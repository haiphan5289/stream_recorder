//
//  AudioMixer.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation
import AVFoundation
import ReplayKit

public class AudioMixer {
    private var outputHander: (CMSampleBuffer) -> (Void)
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var sources: [Int: AudioSource] = [Int: AudioSource]()
    private var renderedBuffer: AVAudioPCMBuffer?
    public var processingFormat: AVAudioFormat
    private var active:Bool = false
    private var audioClock = CMClockGetHostTimeClock()
    private var audioTimebase: CMTimebase?
    private var firstVideoTs: CMTime?
    
    private let maximumFrameCount: AVAudioFrameCount = 1024
    private var maxQueuedSamples = 1024 * 7
    private var silenceDelay: Double = 0.65
    private let pausedSilenceDelay: Double =  5.01 * 1024 / 44100
    private let silenceDuration: Double = 5.01 * 1024 / 44100 //≈116ms
    private let audioAppId = RPSampleBufferType.audioApp.rawValue
    private let audioMicId = RPSampleBufferType.audioMic.rawValue

    
    // MARK: Public Methods
    public func attach(identifier: Int) {
        let source = AudioSource()
        audioEngine.attach(source.playerNode)
        sources[identifier] = source
    }
    
    public func detach(identifier: Int) -> Bool {
        guard let source = sources[identifier] else {
            return false
        }
        audioEngine.detach(source.playerNode)
        sources[identifier] = nil
        return true
    }
    
    public func start() -> Bool {
        do {
            audioEngine.stop()
            if #available(iOS 13.0, *) {
                silenceDelay = 0.5
            } else {
                silenceDelay = 1.3
                maxQueuedSamples = 1024 * 10
            }
            for (type, source) in sources {
                var rate = processingFormat.sampleRate
                if #available(iOS 13.0, *) {
                    //Mic using 48000 on iOS 13
                    rate = type == audioMicId ? 48000.0 : 44100.0
                }
                let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: rate,
                                           channels: AVAudioChannelCount(processingFormat.channelCount),
                                           interleaved: false)

                audioEngine.connect(source.playerNode, to: audioEngine.mainMixerNode, format: format)
            }
            
            try audioEngine.enableManualRenderingMode(.offline, format: processingFormat, maximumFrameCount: maximumFrameCount)
            try audioEngine.start()
            
            for (_, source) in sources {
                source.playerNode.play()
            }
            
            let format = audioEngine.manualRenderingFormat

            renderedBuffer = AVAudioPCMBuffer(pcmFormat: audioEngine.manualRenderingFormat, frameCapacity: audioEngine.manualRenderingMaximumFrameCount)
            
            CMTimebaseSetRate(audioTimebase!, rate: 1.0)
            active = true
            return true
        }
        catch {
            return false
        }
    }
    
    public func stop() {
        active = false
        audioEngine.stop()
        for (_, source) in sources {
            source.playerNode.stop()
        }
     }
    
    public func processBuffer(_ sampleBuffer: CMSampleBuffer, with identifier: Int, pts: CMTime) {
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        let end_pts = pts + duration
        if let pcmBuffer = sampleBuffer.toStandardPCMBuffer( channels: processingFormat.channelCount ) {
            if appendBuffer(identifier: identifier, pcmBuffer: pcmBuffer, ts: end_pts, duration: duration.seconds) == false {
                return
            }
            
            if self.active == false { return }
            if (identifier == audioAppId) {
                CMTimebaseSetTime(audioTimebase!, time: end_pts)
            }
            //DDLogInfo(String(format: "Mix %d async %10.3f %5.1f", identifier, pts.seconds, dt.seconds * 1000))
            let renderStatus = self.render()
            if renderStatus == .error {
            }
        }
    }
    
    public func appendBuffer(identifier: Int, pcmBuffer: AVAudioPCMBuffer, ts: CMTime, duration: Double) -> Bool {
        if let source = sources[identifier] {
            if source.sampleRate <= 0 {
                source.sampleRate = pcmBuffer.format.sampleRate
            }
            if source.end_ts > ts {
                // TODO: try to skip only already generated part
                return false
            }
            source.playerNode.scheduleBuffer(pcmBuffer)
            source.end_ts = ts
            source.duration += duration
            return true
        }
        return false
    }
    
    public func informVideoFrame(ts: CMTime, paused: Bool) {
        guard let source = sources[audioAppId] else {return}
        var lastTs: CMTime?
        var currentTs: CMTime = ts
        if source.end_ts != CMTime.zero {
            lastTs = source.end_ts
            currentTs = CMTimebaseGetTime(audioTimebase!)
        } else {
            // Use video time if we did't receive audio yet
            CMTimebaseSetTime(audioTimebase!, time: ts)
            if firstVideoTs == nil {
                firstVideoTs = ts
            }
        }

        let delay:Double = paused ? pausedSilenceDelay : silenceDelay
        let frameCount = Int(floor(silenceDuration * processingFormat.sampleRate)) & ~1023 //Round down to 1024
        let muteTs = lastTs ?? firstVideoTs!
        if currentTs.seconds - muteTs.seconds > delay {
            if let buffer = generatePCM(frameCount: frameCount ) {
                let sampleRate = processingFormat.sampleRate
                let duration = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(sampleRate))
                let endTs = muteTs + duration
                if appendBuffer(identifier: audioAppId, pcmBuffer: buffer, ts: endTs, duration: duration.seconds) {
                    let msg = String(format: "Generating empty audio ts: %8.3f last %8.3f  duration %1.3f", endTs.seconds, muteTs.seconds, duration.seconds)
                    let renderStatus = self.render()
                    if renderStatus == .error {
                    }
                }
            }
        }
    }
    
    @discardableResult
    public func render() -> AVAudioEngineManualRenderingStatus {
        var status: AVAudioEngineManualRenderingStatus = .insufficientDataFromInputNode
        let renderframeCount = audioEngine.manualRenderingMaximumFrameCount
        guard let renderedBuffer = self.renderedBuffer else { return .error }
        let renderframeDuration:Double = Double(renderframeCount) / processingFormat.sampleRate
        guard let app_source = sources[audioAppId], let mic_source = sources[audioMicId] else { return .error }
        while active {
            let min_duration = min(app_source.duration, mic_source.duration)
//            DDLogInfo("Audio mix: App \(app_source.duration) Mic \(mic_source.duration)")
            let enough_samples = min_duration > renderframeDuration + 0.001 || app_source.samples >= maxQueuedSamples
            if !enough_samples { // Must have either samples for both inputs or plenty of application samples
//                DDLogInfo("Wait for more audio")
                break
            }
            let duration = Double(app_source.samples) / processingFormat.sampleRate
            let ts = app_source.end_ts - CMTime.init(seconds: duration, preferredTimescale: app_source.end_ts.timescale)
            do {
                try status = audioEngine.renderOffline(renderframeCount, to: renderedBuffer)
            } catch {
                return .error
            }
            if status != .success {
                break
            }
            if !mixer(didRender: renderedBuffer, pts: ts) {
                status = .error
                break
            }
            let outDuration = Double(renderedBuffer.frameLength) / processingFormat.sampleRate
            for (_, source) in sources {
                if source.duration > outDuration - 0.001 {
                    source.duration -= outDuration
                }
            }
        }
        return status
    }
    
    private func generatePCM(frameCount: CMItemCount) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: processingFormat.sampleRate, channels: processingFormat.channelCount, interleaved: false) else { return nil }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        buffer.frameLength = buffer.frameCapacity

        return buffer
    }
    
    // MARK: Init Methods
    init?( config: AudioEncoderConfig, outputHander: @escaping (CMSampleBuffer) -> Void ) {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: config.sampleRate,
                                   channels: AVAudioChannelCount(config.channelCount),
                                   interleaved: false)
        self.processingFormat = format!
        self.outputHander = outputHander
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: audioClock, timebaseOut: &audioTimebase)
    }
    
    func mixer(didRender pcmBuffer: AVAudioPCMBuffer, pts: CMTime) -> Bool {
        if active == false { return false }
        if let buffer = pcmBuffer.toStandardSampleBuffer(pts: pts) {
            outputHander(buffer)
            return true
        }
        return false
    }
}

extension AudioMixer {
    fileprivate class AudioSource {
        var playerNode: AVAudioPlayerNode
        var duration: Float64 = 0.0
        var end_ts: CMTime = CMTime.zero
        var sampleRate: Float64 = 0.0
        var samples: Int {
            return sampleRate > 0 ? Int(duration*sampleRate) : 0
        }
        // MARK: Init Methods
        required init() {
            playerNode = AVAudioPlayerNode()
        }
    }
}

extension AVAudioPCMBuffer {
    
    public func toStandardSampleBuffer(pts: CMTime? = nil) -> CMSampleBuffer? {
        
        var sampleBuffer: CMSampleBuffer? = nil
        let based_pts = pts ?? CMTime.zero
        let new_pts = CMTimeMakeWithSeconds(CMTimeGetSeconds(based_pts), preferredTimescale: based_pts.timescale)
        var timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1, timescale: 44100), presentationTimeStamp: new_pts, decodeTimeStamp: CMTime.invalid)

        if ((self.format.streamDescription.pointee.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0) {
            NSLog("Unsupported format");
            return nil
        }
        let channels = UInt32(self.format.channelCount)
        var convert_asbd = AudioStreamBasicDescription(mSampleRate: self.format.sampleRate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked), mBytesPerPacket: channels*2, mFramesPerPacket: 1, mBytesPerFrame: channels*2, mChannelsPerFrame: channels, mBitsPerChannel: 16, mReserved: 0)
        
        guard let convert_format = AVAudioFormat(streamDescription: &convert_asbd),
            let convert_buffer = AVAudioPCMBuffer(pcmFormat: convert_format, frameCapacity: self.frameCapacity) else { return nil }
        
        convert_buffer.frameLength = convert_buffer.frameCapacity
        MixerConvert.covert32bitsTo16bits(self.mutableAudioBufferList,
                                        outputBufferList: convert_buffer.mutableAudioBufferList,
                                        channels: channels)
        
        let createStatus = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                                dataBuffer: nil,
                                                dataReady: false,
                                                makeDataReadyCallback: nil,
                                                refcon: nil,
                                                formatDescription: convert_format.formatDescription,
                                                sampleCount: CMItemCount(self.frameLength),
                                                sampleTimingEntryCount: 1,
                                                sampleTimingArray: &timing,
                                                sampleSizeEntryCount: 0,
                                                sampleSizeArray: nil,
                                                sampleBufferOut: &sampleBuffer)
        if createStatus != noErr || sampleBuffer == nil {
            return nil
        }
        var bbuf: CMBlockBuffer? = nil
        let dataLen:Int = Int(self.frameLength*channels*2)
        let bbCreateStatus = CMBlockBufferCreateEmpty(allocator: kCFAllocatorDefault, capacity: UInt32(dataLen), flags: 0, blockBufferOut: &bbuf)
        if createStatus != noErr || bbuf == nil {
            return nil
        }
        let raw_data_buffer = convert_buffer.mutableAudioBufferList[0].mBuffers.mData
        
        let assignStatus = CMBlockBufferAppendMemoryBlock(bbuf!, memoryBlock: raw_data_buffer, length: dataLen, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: dataLen, flags: 0)
        if assignStatus != noErr {
            return nil
        }

        let setBufferStatus = CMSampleBufferSetDataBuffer(sampleBuffer!, newValue: bbuf!)

        if setBufferStatus != noErr {
            return nil
        }

        return sampleBuffer
    }
}

extension CMSampleBuffer {
    
    public func toAudioBufferList(reorder: Bool) -> (OSStatus, UnsafePointer<AudioBufferList>) {
        let audioBufferList = AudioBufferList.allocate(maximumBuffers: 1)
        var blockBuffer: CMBlockBuffer?
        
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut:  nil,
            bufferListOut: audioBufferList.unsafeMutablePointer,
            bufferListSize:  AudioBufferList.sizeInBytes(maximumBuffers: 1),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        if (status == noErr && reorder == true) {
            MixerConvert.reorderBuffer(audioBufferList.unsafeMutablePointer)
        }
        return (status, audioBufferList.unsafePointer)
    }
    
    public func toStandardPCMBuffer(channels: AVAudioChannelCount) -> AVAudioPCMBuffer? {
        
        if let fmt = CMSampleBufferGetFormatDescription(self), let asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(fmt)?.pointee {
            
            assert(asbd.mFormatID == kAudioFormatLinearPCM, "only support pcm format")
            let reorder:Bool = ((asbd.mFormatFlags & kAudioFormatFlagIsBigEndian) != 0)
            let (status, audioBufferList) = self.toAudioBufferList(reorder: reorder)
            if (status != noErr) {return nil}
            
            let frameCount = CMSampleBufferGetNumSamples(self)
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: asbd.mSampleRate,
                                             channels: channels,
                                             interleaved: false)
                else {return nil}
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }

            buffer.frameLength = buffer.frameCapacity
            if ((asbd.mFormatFlags & kAudioFormatFlagIsSignedInteger) == kAudioFormatFlagIsSignedInteger) {
                MixerConvert.covert16bitsTo32bits(audioBufferList,
                                                outputBufferList: buffer.mutableAudioBufferList,
                                                inputChannels: asbd.mChannelsPerFrame, outputChannels: channels)
            }
            audioBufferList.deallocate()
            return buffer
        }
        
        return nil
    }
}


