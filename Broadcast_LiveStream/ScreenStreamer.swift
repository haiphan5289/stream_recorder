//
//  ScreenStreamer.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation
import CoreImage
import ReplayKit

class ScreenStreamer: NSObject, StreamerEngineDelegate {
    
    static let sharedInstance = ScreenStreamer() // Singleton pattern in Swift
    private var streamWidth: Int = 1920
    private var streamHeight: Int = 1080
    public var orientation: CGImagePropertyOrientation? = .none
    
    private var lastVideoTs: CMTime?
    private var videoTimeAdjustment: CMTime = CMTime.zero //Consider pause time
    private var videoClock = CMClockGetHostTimeClock()
    private var videoTimebase: CMTimebase?
    
    private var frameRepeaterTimer: Timer?
    private var noNewFrames: Bool = false
    private var lastFrame: CMSampleBuffer?
    private let PixelFormat_YUV = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange

    private var alignmentBuffer: FrameAlignmentBuffer
    private var paused = false
    private var needAdjustment = false
    
    weak var delegate: ScreencasterDelegate?
    var config: ScreencastConfig
    var mixer: AudioMixer?
    private var engine: StreamerEngineProxy
    private var connectionList: [Int32] = []
    var streamConditioner: StreamConditioner?
    var frameLock = NSLock()
    
    private override init() {
        config = ScreencastConfig.init()
        engine = StreamerEngineProxy(maxItems: 300)
        alignmentBuffer = FrameAlignmentBuffer(streamerEngine: engine)
        super.init()
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: videoClock, timebaseOut: &videoTimebase)
        engine.setDelegate(self)
        engine.setInterleaving(true)
    }


    // MARK: Rtmp connection
    func createConnection(config: ConnectionConfig) -> Int32 {
        let id = engine.createConnection(config)
        connectionList.append(id)
        return id
    }
    
    func createConnection(config: SrtConfig) -> Int32 {
        let id = engine.createSrtConnection(config)
        connectionList.append(id)
        return id
    }
    
    func releaseConnection(id: Int32) {
        if let n = connectionList.firstIndex(of: id) {
            engine.releaseConnection(id)
            connectionList.remove(at: n)
            streamConditioner?.removeConnection(id: id)
        }
    }
    
    func releaseAllConnections() {
        for id in connectionList {
            engine.releaseConnection(id)
            streamConditioner?.removeConnection(id: id)

        }
        connectionList.removeAll()
    }
    
    // MARK: Rtmp connection: notifications
    public func connectionStateDidChangeId(_ connectionID: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
        delegate?.connectionStateDidChange(id: connectionID, state: state, status: status, info: info)
    }
    
    func startCapture() -> CaptureStatus {
        createStreamConditioner()

        engine.setVideoConfig(createVideoEncoderConfig())
        if !engine.startVideoEncoding() {
            return .CaptureStatusErrorVideo
        }
        setupOrientation()

        alignmentBuffer.bufferTime = Double(config.frameBufferMs) / 1000
        alignmentBuffer.beforeFirstFrame = {
            self.streamConditioner?.start(bitrate: self.config.videoBitrate, id: Array(self.connectionList))
        }
        if alignmentBuffer.start(config: config) == false {
            return .CaptureStatusErrorVideo
        }
        CMTimebaseSetRate(videoTimebase!, rate: 1.0)
        
        let audioConfig = createAudioEncoderConfig()
        engine.setAudioConfig(audioConfig)
        var status:CaptureStatus = .CaptureStatusErrorAudio
        mixer = AudioMixer.init(config: audioConfig, outputHander: { self.alignmentBuffer.putAudioFrame($0) } )
        guard let mixer = mixer else { return .CaptureStatusErrorAudio }
        mixer.attach(identifier: RPSampleBufferType.audioApp.rawValue)
        mixer.attach(identifier: RPSampleBufferType.audioMic.rawValue)
        if mixer.start() {
            status = .CaptureStatusSuccess
        }

        return status
    }
   
    private func createAudioEncoderConfig() -> AudioEncoderConfig {
        let encoderConfig = AudioEncoderConfig()

        encoderConfig.channelCount = Int32(config.channelCount)
        encoderConfig.sampleRate = config.sampleRate
        encoderConfig.bitrate = Int32(config.audioBitrate)
        encoderConfig.manufacturer = kAppleSoftwareAudioCodecManufacturer
        
   
        
        return encoderConfig
    }
    
    private func createVideoEncoderConfig() -> VideoEncoderConfig {
        let encoderConfig = VideoEncoderConfig()

        streamWidth = Int(config.verticalStream ? config.videoSize.width : config.videoSize.height)
        streamHeight = Int(config.verticalStream ? config.videoSize.height : config.videoSize.width)
        
        encoderConfig.pixelFormat = PixelFormat_YUV
        
        encoderConfig.width = Int32(streamWidth)
        encoderConfig.height = Int32(streamHeight)
        encoderConfig.fps = Int32(config.fps)
        encoderConfig.maxKeyFrameInterval = Int32(config.keyFrameIntervalDuration * config.fps)
        encoderConfig.type = config.codecType
        encoderConfig.profileLevel = config.profileLevel as String
        encoderConfig.bitrate = Int32(config.videoBitrate) // kVTCompressionPropertyKey_AverageBitRate
        encoderConfig.limit = Int32(config.videoBitrate*2) // optional kVTCompressionPropertyKey_DataRateLimits property
        
       
        
        return encoderConfig
    }
    
    func stopCapture() {
        streamConditioner?.stop()
        frameRepeaterTimer?.invalidate()
        alignmentBuffer.stop()
        mixer?.stop()
        engine.stopVideoEncoding()
        engine.stopAudioEncoding()
        lastFrame = nil
        frameRepeaterTimer = nil
        streamConditioner  = nil
    }
    
    func pause() {
        paused = true
    }
    
    func resume() {
        paused = false
        needAdjustment = true
    }

    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
//        DDLogInfo("processSampleBuffer >> \(sampleBufferType.rawValue)")

        frameLock.lock()
        switch sampleBufferType {
        case .video:
//            let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//            DDLogDebug(String(format: "Video buffer %f", ts.seconds))
            processVideoBuffer(sampleBuffer)
            if frameRepeaterTimer == nil {
                startFrameTimer()
            }
        case .audioMic, .audioApp:
//            let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//            let duration = CMSampleBufferGetDuration(sampleBuffer)
//            let samples = CMSampleBufferGetNumSamples(sampleBuffer)
//            let desc = CMSampleBufferGetFormatDescription(sampleBuffer)
//            var rate: Double = 0.0
//            let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(desc!)
//            rate = audioDesc?.pointee.mSampleRate ?? 0.0
//
//            DDLogDebug(String(format:"Audio buffer %@ ts %8.3f duration %2.3f (%d samples @ %f)", (sampleBufferType == .audioApp ? "App" : "Mic"), ts.seconds, duration.seconds, samples, rate))
            let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer) + videoTimeAdjustment
            mixer?.processBuffer(sampleBuffer, with: sampleBufferType.rawValue, pts: sampleTime)
        default:
            break
        }
        frameLock.unlock()
//        DDLogInfo("processSampleBuffer <<")
    }
    
    private func processVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        noNewFrames = false
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer) + videoTimeAdjustment
        // Need to adust PTS if we did generate some frames on pause
        if lastVideoTs != nil && needAdjustment {
            videoTimeAdjustment = lastVideoTs! - CMSampleBufferGetPresentationTimeStamp(sampleBuffer) + CMTime(seconds: 1/60, preferredTimescale: sampleTime.timescale)
            needAdjustment = false
        }
        CMTimebaseSetTime(videoTimebase!, time: sampleTime)
        lastVideoTs = sampleTime
        lastFrame = sampleBuffer
        if config.orientation == .FollowScreen || (config.orientation == .Locked && orientation == .none) {
            if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) {
                //NSLog("Orientation: %d", orientationAttachment.uint32Value)
                orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value)
            }
        }

        alignmentBuffer.putVideoFrame(sampleBuffer, frameTs: sampleTime.seconds, orientation: orientation ?? .up)
        mixer?.informVideoFrame(ts: sampleTime, paused: false)
    }
    
    private func setupOrientation() {
        switch config.orientation {
        case .Portrait:
            orientation = .up
        case .Landscape:
            orientation = .right
        case .FollowScreen, .Locked:
            orientation = .none
        }
    }
    
    func startFrameTimer() {
        let interval:TimeInterval = 1.0/25.0
        DispatchQueue.main.sync {
            self.frameRepeaterTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                self.frameRepeater()
            }
        }
    }
    
  func frameRepeater() {
    let interval:TimeInterval = 1.0/50.0
    let limit = Date(timeIntervalSinceNow: interval)
    if !frameLock.lock(before: limit) {
        return
    }
    if noNewFrames && lastFrame != nil {
        let frameTime = CMTimebaseGetTime(videoTimebase!)
        lastVideoTs = frameTime
        if (paused) {
            alignmentBuffer.putBlankFrame(frameTs: frameTime.seconds)
            mixer?.informVideoFrame(ts: frameTime, paused: true)
            return
        }
        alignmentBuffer.putVideoFrame(lastFrame!, frameTs: frameTime.seconds, orientation: orientation ?? .up)
        mixer?.informVideoFrame(ts: frameTime, paused: false)
    }
    noNewFrames = true
    frameLock.unlock()
    }
    
    //MARK: Adaptive bitrate
    func createStreamConditioner() {
        streamConditioner = StreamConditionerMode2()
//        switch Settings.sharedInstance.abrMode {
//        case 1:
//            streamConditioner = StreamConditionerMode1()
//        case 2:
//            streamConditioner = StreamConditionerMode2()
//        default:
//            break
//        }
    }
    
    func audioPacketsLost(connection: Int32) -> UInt64 {
        return engine.getAudioPacketsLost(connection)
    }
    
    func videoPacketsLost(connection: Int32) -> UInt64 {
        return engine.getVideoPacketsLost(connection)
    }
    
    func udpPacketsLost(connection: Int32) -> UInt64 {
        return engine.getUdpPacketsLost(connection)
    }
    
    public func changeBitrate(newBitrate: Int32) {
        engine.updateBitrate(newBitrate)
    }
}

