//
//  RootVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class RootVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.direction()
    }
    
    private func direction() {
        RemoteConfigManager.shared.doneCallBack = {
            if RemoteConfigManager.shared.boolValue(forkey: .showOnboard) {
                Cache.shared.showOnboard = true
            } else {
                Cache.shared.showOnboard = false
            }
            
            if RemoteConfigManager.shared.boolValue(forkey: .lockFeature) {
                Cache.shared.lockFeature = true
            } else {
                Cache.shared.lockFeature = false
            }
            
            if RemoteConfigManager.shared.boolValue(forkey: .showInappHome) {
                Cache.shared.showInappHome = true
            } else {
                Cache.shared.showInappHome = false
            }
            
            if RemoteConfigManager.shared.boolValue(forkey: .lockAllFeature) {
                Cache.shared.lockAllFeature = true
            } else {
                Cache.shared.lockAllFeature = true
            }
            
            print(RemoteConfigManager.shared.boolValue(forkey: .showOnboard))
            print(RemoteConfigManager.shared.boolValue(forkey: .showInappHome))
            
            self.blockApp()
        }
    }
    
    private func blockApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if Cache.shared.showOnboard {
                let vc = initVC("OnboardVC") as! OnboardVC
                self.navigationController?.pushViewController(vc, animated: false)
            } else {
                Application.shared.gotoTabbar()
            }
        }
    }

}
