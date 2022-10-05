//
//  ScreencastConfig.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation
import VideoToolbox
import UIKit

enum StreamOrientation: Int {
    case Portrait = 0
    case Landscape = 1
    case Locked = 2
    case FollowScreen = 3
}

struct ScreencastConfig {
    
    init() {
        let settings = Settings.sharedInstance
        videoSize = settings.resolution
        fps = 60.0
        keyFrameIntervalDuration = 2.0
        videoBitrate = 3000 * 1000
        codecType = kCMVideoCodecType_H264
        profileLevel = kVTProfileLevel_H264_Baseline_AutoLevel
        sampleRate = 44100.0
        channelCount = 2
        audioBitrate = 96000
        orientation = .FollowScreen
        verticalStream = false
        frameBufferMs = 0
    }
    var videoSize: CMVideoDimensions
    var fps: Double
    var keyFrameIntervalDuration: Double
    var videoBitrate: Int
    var codecType: CMVideoCodecType
    var profileLevel: CFString
    var orientation: StreamOrientation
    var verticalStream: Bool
    
    var sampleRate: Double
    var channelCount: Int
    var audioBitrate: Int
    
    var frameBufferMs: Int
}


