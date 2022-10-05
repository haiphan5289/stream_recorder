//
//  FrameAlignmentBuffer.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation

class FrameAlignmentBuffer {
    enum SampleType {
        case Video
        case VideoBlank
        case Audio
        
        var desc: String {
            switch self {
            case .Video:
                return "V"
            case .VideoBlank:
                return "◊"
            case .Audio:
                return "A"
            }
        }
    }
    struct BufferData {
        var timestamp: Double
        var sampleType: SampleType
        var sampleBuffer: CMSampleBuffer?
        var orientation: CGImagePropertyOrientation?
    }
    typealias Handler = () -> Void
    public var bufferTime: Double = 1.0
    public var beforeFirstFrame: Handler?

    private let videoTimescale: CMTimeScale = 1000000
    private let timerInterval: TimeInterval = 1/300

    private var engine: StreamerEngineProxy
    private var postprocessor: VideoPostprocessor?
    private var pausedFrame: CVPixelBuffer?
    private var frameWidth: Int = 1920
    private var frameHeight: Int = 1080
    private var frameBuffer = Array<BufferData>()
    private var videoClock = CMClockGetHostTimeClock()
    private var videoTimebase: CMTimebase?
    private var runTimer: Timer?
    private var semaphore = DispatchSemaphore(value: 1)
    private var lastVideoTime: Double?
    private var lastAudioTime: Double?
    private var audioFramesCount: Int = 0
    private var videoFramesCount: Int = 0
    private var firstFrame: Bool = false
    
    init(streamerEngine: StreamerEngineProxy) {
        engine = streamerEngine
        //dynamicLogLevel = .warning
    }
    
    func start(config: ScreencastConfig) -> Bool {
        lastAudioTime = nil
        lastVideoTime = nil
        frameWidth = Int(config.verticalStream ? config.videoSize.width : config.videoSize.height)
        frameHeight = Int(config.verticalStream ? config.videoSize.height : config.videoSize.width)
        if !(config.verticalStream && config.orientation == .Portrait) {
            postprocessor = VideoPostprocessorVImage()
            postprocessor?.verticalStream = config.verticalStream
            postprocessor?.videoSize = config.videoSize
            postprocessor?.streamWidth = Int(config.verticalStream ? config.videoSize.width : config.videoSize.height)
            postprocessor?.streamHeight = Int(config.verticalStream ? config.videoSize.height : config.videoSize.width)
        }
        firstFrame = true
        return postprocessor?.start() ?? true
    }
    
    func stop() {
        runTimer?.invalidate()
        while !frameBuffer.isEmpty {
            outputFrame(immediate: true)
        }
        postprocessor?.stop()
        videoTimebase = nil
        runTimer = nil
    }
    
    func putVideoFrame(_ buffer: CMSampleBuffer, frameTs withTime: Double, orientation: CGImagePropertyOrientation) {
        let data = BufferData(timestamp: withTime, sampleType: .Video, sampleBuffer: buffer, orientation: orientation)
        if bufferTime > 0 {
            putElement(data)
        } else {
            checkFirstFrame()
            outputVideoFrame(data)
        }
    }
    
    func putBlankFrame(frameTs withTime: Double) {
        let data = BufferData(timestamp: withTime, sampleType: .VideoBlank, sampleBuffer: nil, orientation: nil)
        if bufferTime > 0 {
            putElement(data)
        } else {
            checkFirstFrame()
            outputBlankFrame(data)
        }
    }
    
    func putAudioFrame(_ buffer: CMSampleBuffer) {
        if bufferTime > 0 {
            let frameTime = CMSampleBufferGetPresentationTimeStamp(buffer)
            let data = BufferData(timestamp: frameTime.seconds, sampleType: .Audio, sampleBuffer: buffer, orientation: nil)
            putElement(data)
        } else {
            checkFirstFrame()
            engine.didOutputAudioSampleBuffer(buffer)
        }
    }
    
    private func putElement(_ element: BufferData) {
        let ts = element.timestamp
        syncrhoized (interval: nil, block: {
            let lastTs = frameBuffer.last?.timestamp ?? 0
            if lastTs <= element.timestamp {
                frameBuffer.append(element)
            } else {
                if let pos = frameBuffer.lastIndex(where: {$0.timestamp <= ts}) {
                    frameBuffer.insert(element, at: pos+1)
                } else {
                    let firstTs = frameBuffer.first?.timestamp ?? -1
                    frameBuffer.insert(element, at: 0)
                }
            }
            if (element.sampleType == .Audio) {
                audioFramesCount += 1
            } else {
                videoFramesCount += 1
            }
            //assert(validateTimestamps())
        })
        if runTimer == nil {
            initTimer()
        }
    }
    
    private func outputVideoFrame(_ data: BufferData ) {
        guard let frame = data.sampleBuffer else {return}
        let ts: CMTime = CMTime(seconds: data.timestamp, preferredTimescale: videoTimescale)
 
        if postprocessor == nil {
            var frameOut: CMSampleBuffer? = frame
            let frameTs = CMSampleBufferGetPresentationTimeStamp(frame)
            if frameTs != ts {
                frameOut = copyFrameWithNewTs(frame, ts: ts)
            }
            if frameOut != nil {
                engine.didOutputVideoSampleBuffer(frameOut!)
            }
        } else {
            if let orientation = data.orientation, let outBuffer = postprocessor!.rotateAndEncode(frame, orientation: orientation) {
                engine.didOutputVideoPixelBuffer(outBuffer, withPresentationTime: ts)
            } else {
            }
        }
    }
    
    private func outputBlankFrame(_ data: BufferData ) {
        if let outBuffer = getPausedFrame() {
            let pts = CMTime(seconds: data.timestamp, preferredTimescale: videoTimescale)
            engine.didOutputVideoPixelBuffer(outBuffer, withPresentationTime: pts)
        }
    }

    private func outputFrame(immediate: Bool = false) {
        var firstFrame: BufferData?
        syncrhoized (interval: timerInterval * 0.75, block: {
            guard let frame = frameBuffer.first else {
                return
            }
            if videoTimebase == nil {
                initTimebase(frame.timestamp)
            }
            if immediate == false && (audioFramesCount == 0 || videoFramesCount == 0) {
                return
            }
            let frameTs = frame.timestamp
            let runTime = CMTimebaseGetTime(videoTimebase!)
            if (immediate == false && runTime.seconds < frameTs) {
                return
            }
            firstFrame = frameBuffer.removeFirst()
            if frame.sampleType == .Audio {
                audioFramesCount -= 1
            } else {
                videoFramesCount -= 1
            }
        })
        guard let frame = firstFrame else {
            return
        }
        let lastFrameTime = (frame.sampleType == .Audio ? lastAudioTime : lastVideoTime) ?? 0
        if frame.timestamp < lastFrameTime {
            return
        }
        checkFirstFrame()
        switch frame.sampleType {
        case .Video:
            outputVideoFrame(frame)
            lastVideoTime = frame.timestamp
        case .VideoBlank:
            outputBlankFrame(frame)
            lastVideoTime = frame.timestamp
        case .Audio:
            engine.didOutputAudioSampleBuffer(frame.sampleBuffer)
            lastAudioTime = frame.timestamp
        }
    }
    
    private func initTimer() {
        let firstFrameTime = Date(timeIntervalSinceNow: bufferTime)
        runTimer = Timer(fire: firstFrameTime, interval: timerInterval, repeats: true, block: { (_) in
            self.outputFrame()
        })
        RunLoop.main.add(runTimer!, forMode: .common)
    }
    
    private func initTimebase(_ ts: Double) {
        let startTime = CMTime(seconds: ts, preferredTimescale: videoTimescale)
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: videoClock, timebaseOut: &videoTimebase)
        assert(videoTimebase != nil)
        CMTimebaseSetTime(videoTimebase!, time: startTime)
        CMTimebaseSetRate(videoTimebase!, rate: 1.0)
    }
    
    
    private func copyFrameWithNewTs(_ frame: CMSampleBuffer, ts: CMTime) -> CMSampleBuffer? {
        var sOut: CMSampleBuffer?
        let count: CMItemCount = 1
        let duration = CMSampleBufferGetDuration(frame)
        var pInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: ts, decodeTimeStamp: ts)
        
        let status = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                                           sampleBuffer: frame,
                                                           sampleTimingEntryCount: count,
                                                           sampleTimingArray: &pInfo,
                                                           sampleBufferOut: &sOut)
        if status == noErr {
            return sOut
        } else {
            return nil
        }
    }
    
    private func getPausedFrame() -> CVPixelBuffer? {
        return pausedFrame
    }
    private func checkFirstFrame() {
        if firstFrame {
            beforeFirstFrame?()
            firstFrame = false
        }
    }
    private func syncrhoized(interval: Double?,  block: Handler) {
        let endTime:DispatchTime = interval == nil ? DispatchTime.distantFuture : DispatchTime.now() + DispatchTimeInterval.microseconds(Int(interval! * 1e6))
        if semaphore.wait(timeout: endTime) == .timedOut {
            return
        }
        block()
        semaphore.signal()
    }
    
//    private func validateTimestamps() -> Bool {
//        var lastTs: Double = 0
//        for sample in frameBuffer {
//            if sample.timestamp < lastTs {
//                DDLogError("Out of order \(sample.timestamp) < \(lastTs)")
//                return false
//            }
//            lastTs = sample.timestamp
//        }
//        return true
//    }

}



