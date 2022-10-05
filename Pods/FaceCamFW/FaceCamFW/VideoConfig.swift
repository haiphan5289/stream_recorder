// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/FrequentlyAskedQuestions/FrequentlyAskedQuestions.html

// Although the protocol specification does not limit the video and audio formats, the current Apple implementation supports the following video formats:
// H.264 Baseline Level 3.0, Baseline Level 3.1, Main Level 3.1, and High Profile Level 4.1.

// kVTProfileLevel_H264_Baseline_AutoLevel
// kVTProfileLevel_H264_Main_AutoLevel
// kVTProfileLevel_H264_High_AutoLevel

import AVFoundation
import VideoToolbox

public struct VideoConfig {
    public var cameraID: String
    public var videoSize: CMVideoDimensions
    public var fps: Double // AVFrameRateRange
    public var keyFrameIntervalDuration: Double
    public var bitrate: Int
    public var portrait: Bool
    public var type: CMVideoCodecType
    public var profileLevel: CFString
    
    public init(cameraID: String, videoSize: CMVideoDimensions, fps: Double, keyFrameIntervalDuration: Double, bitrate: Int, portrait: Bool, type: CMVideoCodecType, profileLevel: CFString) {
        self.cameraID = cameraID
        self.videoSize = videoSize
        self.fps = fps
        self.keyFrameIntervalDuration = keyFrameIntervalDuration
        self.bitrate = bitrate
        self.portrait = portrait
        self.type = type
        self.profileLevel = profileLevel
    }
}

public struct AudioConfig {
    public var sampleRate: Double // AVAudioSession.sharedInstance().sampleRate
    public var channelCount: Int
    public var bitrate: Int
    
    public init(sampleRate: Double, channelCount: Int, bitrate: Int) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitrate = bitrate
    }
}
