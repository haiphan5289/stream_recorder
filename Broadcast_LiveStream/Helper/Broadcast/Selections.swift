//
//  Selections.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation

import Foundation

enum CdnSelection : String, CustomStringConvertible {
    case Default = "Default (no authorization)"
    case Llnw = "Limelight Networks"
    case Periscope = "Periscope Producer"
    case RTMP = "RTMP authorization"
    case Akamai = "Akamai/Dacast"
    var description : String { return NSLocalizedString(rawValue, comment: "") }
    
    static let allValues = [Default, RTMP, Akamai, Llnw, Periscope]
}

enum ScreenOrientationSelection : String, CustomStringConvertible {
    case Vertical = "Vertical"
    case Horizontal = "Horizontal"
    case Determine = "Determine at start"
    case Rotate = "Rotate with device"
    
    var description : String { return NSLocalizedString(rawValue, comment: "") }
    
    static let allValues = [Vertical, Horizontal, Determine, Rotate]
}

enum VideoCodecSelection : String, CustomStringConvertible {
    case H264 = "H.264"
    case Hevc = "HEVC"
    
    var description : String { return NSLocalizedString(rawValue, comment: "") }
    
    static let allValues = [H264, Hevc]
}

enum AbrModeSelection: String, CustomStringConvertible {
    case None = "None"
    case Mode1 = "Logarithmic descend"
    case Mode2 = "Ladder ascend"
    
    var description : String { return NSLocalizedString(rawValue, comment: "") }
    static let allValues = [None, Mode1, Mode2]
}

enum ResolutionSelection : String, CustomStringConvertible {
    case Res_Default = "Match display"
    case Res_1080 = "1080p"
    case Res_720 = "720p"
    
    var description : String { return NSLocalizedString(rawValue, comment: "") }
    
    static let allValues = [Res_Default, Res_1080, Res_720]
}
