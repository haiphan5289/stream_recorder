//
//  Cache.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

enum NameKeys: String {
    case onBoard
    case resolution
    case bitrate
    case framerate
    case dualCamera
    case camera
    case videoFormat
    case saveVideo
    case stereoAudio
    case adaptiveBitrate
    case adeptiveFramerate
    case premium
    case showOnBoard
    case lockFeature
    case showInappHome
    case lockAllFeature
}

class Cache: NSObject {
    static let shared = Cache()
    private let uStandard = UserDefaults.standard
    
    private func setValue(value: Any, key: NameKeys) {
        self.uStandard.set(value, forKey: key.rawValue)
        self.uStandard.synchronize()
    }
    
    private func getValue(key: NameKeys) -> Any? {
        guard let value = uStandard.value(forKey: key.rawValue) else { return nil }
        return value
    }
    
    func removeValue(key: NameKeys) {
        self.uStandard.removeObject(forKey: key.rawValue)
        self.uStandard.synchronize()
    }
    
    var onBoard: Bool {
        get {
            self.getValue(key: .onBoard) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .onBoard)
        }
    }
    
    var camera: Bool {
        get {
            self.getValue(key: .camera) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .camera)
        }
    }
    
    var dualCamera: Bool {
        get {
            self.getValue(key: .dualCamera) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .dualCamera)
        }
    }
    
    var adaptiveBitrate: Bool {
        get {
            self.getValue(key: .adaptiveBitrate) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .adaptiveBitrate)
        }
    }
    
    
    var adeptiveFramerate: Bool {
        get {
            self.getValue(key: .adeptiveFramerate) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .adeptiveFramerate)
        }
    }
    
    var bitrate: String {
        get {
            self.getValue(key: .bitrate) as? String ?? "12Mbps"
        }
        set {
            self.setValue(value: newValue, key: .bitrate)
        }
    }
    
    var frameRate: String {
        get {
            self.getValue(key: .framerate) as? String ?? "20 fps"
        }
        set {
            self.setValue(value: newValue, key: .framerate)
        }
    }
    
    var resolution: String {
        get {
            self.getValue(key: .resolution) as? String ?? "360P (SD)"
        }
        set {
            self.setValue(value: newValue, key: .resolution)
        }
    }
    
    var saveVideo: Bool {
        get {
            self.getValue(key: .saveVideo) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .saveVideo)
        }
    }
    
    var stereoAudio: Bool {
        get {
            self.getValue(key: .stereoAudio) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .stereoAudio)
        }
    }
    
    var videoFormat: Bool {
        get {
            self.getValue(key: .videoFormat) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .videoFormat)
        }
    }
    
    var premium: Bool {
        get {
            self.getValue(key: .premium) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .premium)
        }
    }
    
    var url: String? {
        get {
            let value = UserDefaults(suiteName: "group.com.recordscreen11")?.string(forKey: "url")
            return value
        }
        set {
            UserDefaults(suiteName: "group.com.recordscreen11")?.setValue(newValue, forKey: "url")
        }
    }
    
    var key: String? {
        get {
            let value = UserDefaults(suiteName: "group.com.recordscreen11")?.string(forKey: "key")
            return value
        }
        set {
            UserDefaults(suiteName: "group.com.recordscreen11")?.setValue(newValue, forKey: "key")
        }
    }
    
    var showOnboard: Bool {
        get {
            self.getValue(key: .showOnBoard) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .showOnBoard)
        }
    }
    
    var lockFeature: Bool {
        get {
            self.getValue(key: .lockFeature) as? Bool ?? true
        }
        set {
            self.setValue(value: newValue, key: .lockFeature)
        }
    }
    
    var showInappHome: Bool {
        get {
            self.getValue(key: .showInappHome) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .showInappHome)
        }
    }
    
    var lockAllFeature: Bool {
        get {
            self.getValue(key: .lockAllFeature) as? Bool ?? false
        }
        set {
            self.setValue(value: newValue, key: .lockAllFeature)
        }
    }
    
}
