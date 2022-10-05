//
//  Constants.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

func DLog(_ object: Any, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    #if DEBUG
    let className = (fileName as NSString).lastPathComponent
    print("<\(className)> \(functionName) [#\(lineNumber)]|")
    #endif
}

let heightScreen = UIScreen.main.bounds.height
let widthScreen = UIScreen.main.bounds.width

var isShowKB: Bool = false

let applicationDelegate = UIApplication.shared.delegate as! AppDelegate

func initVC(_ nameSB: String, storyID: String = "") -> UIViewController {
    let nameSB = nameSB
    let idVC = storyID.isEmpty ? nameSB : storyID
    let SB = UIStoryboard(name: nameSB, bundle: nil)
    let VC = SB.instantiateViewController(withIdentifier: idVC)
    return VC
}

enum PlatformType: String {
    case Facebook
    case Youtube
    case Twitch
    case Tiktok
    case Twitter
    case RTMP
    
    var image: UIImage? {
        switch self {
        case .Facebook:
            return UIImage(named: "img_fb")
        case .Youtube:
            return UIImage(named: "img_yt")
        case .Twitch:
            return UIImage(named: "img_twitch")
        case .Tiktok:
            return UIImage(named: "img_tiktok")
        case .Twitter:
            return UIImage(named: "img_twitter")
        case .RTMP:
            return UIImage(named: "img_rtmp")
        }
    }
    
    var name: String {
        switch self {
        case .Facebook:
            return "Facebook"
        case .Youtube:
            return "Youtube"
        case .Twitch:
            return "Twitch"
        case .Tiktok:
            return "Tiktok"
        case .Twitter:
            return "Twitter"
        case .RTMP:
            return "RTMP"
        }
    }
    
    var title: String {
        switch self {
        case .Facebook:
            return "Livestream to Facebook"
        case .Youtube:
            return "Livestream to Youtube"
        case .Twitch:
            return "Livestream to Twitch"
        case .Tiktok:
            return "Livestream to Tiktok"
        case .Twitter:
            return "Livestream to Twitter"
        case .RTMP:
            return "Livestream to RTMP"
        }
    }
}

enum CameraType: CaseIterable {
    case dualCamera
    case camera
    
    var title: String {
        switch self {
        case .dualCamera:
             return "Dual Camera"
        case .camera:
            return "Camera"
        }
    }
    
    var type: String {
        switch self {
        case .camera:
            return "BACK CAMERA"
        case .dualCamera:
            return "PICTURE IN PICTURE"
        }
    }
}

enum ParamType: CaseIterable {
    case videoFormat
    case resolution
    case frameRate
    case saveVideo
    case enableStereo
    
    var title: String {
        switch self {
        case .resolution:
            return "Resolution"
        case .videoFormat:
            return "Video Format"
        case .frameRate:
            return "Frame Rate"
        case .saveVideo:
            return "Save video to camera roll"
        case .enableStereo:
            return "Enable stereo audio"
        }
    }
    
    var type: [String] {
        switch self {
        case .videoFormat:
            return ["Landscape", "Portrait"]
        case .resolution:
            return ["SD", "HD", "1080p"]
        case .frameRate:
            return ["15", "25", "30", "50", "60"]
        case .saveVideo:
            return []
        case .enableStereo:
            return []
        }
    }
    
    var width: CGFloat {
        switch self {
        case .videoFormat:
            return 187 * 375/widthScreen
        case .resolution:
            return 160 * 375/widthScreen
        case .frameRate:
            return 244 * 375/widthScreen
        default:
            return 0.0
        }
    }
}

enum VideoType: String, CaseIterable {
    case resolution
    case bitrate
    case framerate
    
    var title: String {
        switch self {
        case .bitrate:
            return "Bitrate"
        case .resolution:
            return "Video Resolution"
        case .framerate:
            return "Frame rate"
        }
    }
    
    var subTitle: String {
        switch self {
        case .bitrate:
            return "Tip: The higher the bitrate, the higher the image quality\n of the video and the larger the size of the video file."
        case .resolution:
            return "Tip: The higher the resolution, the clearer the video\n details and the larger the size of the video file"
        case .framerate:
            return "Tip: The higher the frame rate, the higher the image smoothness\n of the video and the larger the size of the video file."
        }
    }
    
    var data: [String] {
        switch self {
        case .bitrate:
            return ["Auto", "1Mbps", "2Mbps", "3Mbps", "5Mbps", "8Mbps", "12Mbps"]
        case .resolution:
            return ["4K", "2K", "1080P (HD)", "720P (HD)", "480P (SD)", "360P (SD)"]
        case .framerate:
            return ["Auto", "60 fps", "30 fps", "25 fps", "24 fps", "20 fps"]
        }
    }
}

enum ScreenRecordState {
    case start
    case stop
    
    var image: UIImage? {
        switch self {
        case .start:
            return UIImage(named: "ic_recoder_start")
        case .stop:
            return UIImage(named: "ic_recoder_stop")
        }
    }
}

enum SettingType: CaseIterable {
    case upgrade
    case contact
    case rateApp
    case shareApp
    case privacyPolicy
    case terms
    
    var title: String {
        switch self {
        case .upgrade:
            return "Upgrade to Pro"
        case .contact:
            return "Contact us"
        case .rateApp:
            return "Rate App"
        case .shareApp:
            return "Share App"
        case .privacyPolicy:
            return "Privacy Policy"
        case .terms:
            return "Terms & Conditions"
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .upgrade:
            return UIImage(named: "ic_upgrade")
        case .contact:
            return UIImage(named: "ic_contact")
        case .rateApp:
            return UIImage(named: "ic_rate_app")
        case .shareApp:
            return UIImage(named: "ic_share_app")
        case .privacyPolicy:
            return UIImage(named: "ic_privacy")
        case .terms:
            return UIImage(named: "ic_terms")
        }
    }
}

enum VideoToolType: CaseIterable {
    case faceCam
    case videoEditor
    
    var icon: UIImage? {
        switch self {
        case .faceCam:
            return UIImage(named: "img_facecam")
        case .videoEditor:
            return UIImage(named: "img_videoedit")
        }
    }
    
    var title: String {
        switch self {
        case .faceCam:
            return "Face Camera"
        case .videoEditor:
            return "Video Editor"
        }
    }
}

class Common: NSObject {
    static let shared = Common()
    
    func makeCircleContext(size: CGSize, backgroundColor: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(backgroundColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        let bounds = CGRect(origin: .zero, size: size)
        context?.addEllipse(in: bounds)
        context?.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

//func getTopVC(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
//
//    if let nav = base as? UINavigationController {
//        return getTopVC(base: nav.visibleViewController)
//
//    } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
//        return getTopVC(base: selected)
//
//    } else if let presented = base?.presentedViewController {
//        return getTopVC(base: presented)
//    }
//    return base
//}
