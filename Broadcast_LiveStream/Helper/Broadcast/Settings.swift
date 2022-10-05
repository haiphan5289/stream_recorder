//
//  Settings.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import VideoToolbox
import UIKit

class Settings {
    
    static let sharedInstance = Settings() // Singleton pattern in Swift
   
    private let supportedResoltions = [1080: CMVideoDimensions(width: 1080, height: 1920), 720: CMVideoDimensions(width: 720, height: 1280)]
    private let resolution_key = "pref_resolution"
    
    var resolution: CMVideoDimensions {
        let screenRect = UIScreen.main.nativeBounds
        let resKey = 1080
        if var res = supportedResoltions[resKey] {
            //If no image processing, adjust width to match original aspect ratio
            if !imageProcessingMode {
                res.height = Int32((CGFloat(res.width) * screenRect.height / screenRect.width).rounded())
                res.height -= res.height % 2 // Make it even
            }
            if res.width <= Int(screenRect.width) || res.height <= Int(screenRect.height) {
                //Only if selected resolution doesn't exceed screen size (no upscaling)
                return res
            }
        }
        
        var w = screenRect.width
        var h = screenRect.height
        if imageProcessingDisabled {
            w = 1200.0
            h = 1600.0
        }
        return CMVideoDimensions(width: Int32(w), height: Int32(h))
    }
    
    var verticalStream: Bool {
        return false
    }
    
    var imageProcessingDisabled: Bool {
        return false
    }
    
    var imageProcessingMode: Bool {
        return verticalStream == false
    }
}


