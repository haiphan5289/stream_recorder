//
//  RemoteConfig.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import FirebaseRemoteConfig

enum Configkey: String {
    case showOnboard
    case lockFeature
    case showInappHome
    case lockAllFeature
}

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    var doneCallBack: () -> Void = {}
    
    private init() {
        loadValues()
        fetchValues()
    }
    
    func fetchValues() {
        let setting  = RemoteConfigSettings()
        RemoteConfig.remoteConfig().configSettings = setting
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: 0) {
            [weak self] (status, error) in
            if let error = error {
                print(error)
                return
            }
            
            RemoteConfig.remoteConfig().activate { status, error in
                if let error = error {
                    print(error)
                    return
                }
                self?.doneCallBack()
            }
        }
    }
    
    func loadValues() {
        let defaults: [String: Any?] = [
            Configkey.showOnboard.rawValue: false,
            Configkey.lockFeature.rawValue: true,
            Configkey.showInappHome.rawValue: false,
            Configkey.lockAllFeature.rawValue: false
        ]
        RemoteConfig.remoteConfig().setDefaults(defaults as? [String: NSObject])
    }
    
    func boolValue(forkey key: Configkey) -> Bool {
        return RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
}
