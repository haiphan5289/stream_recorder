//
//  AppDelegate.swift
//  LiveStream
//
//  Created by htv on 09/08/2022.
//

import UIKit
import AVKit
import SwiftyStoreKit
import HaishinKit
import Firebase
import FaceCamFW

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var restrictRotation: UIInterfaceOrientationMask = .portrait
    weak var mainView: ApplicationStateObserver?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.setup()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    private func setup() {
        FirebaseApp.configure()
        let session = AVAudioSession.sharedInstance()
        do {
            session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                AVAudioSession.CategoryOptions.allowBluetooth,
                AVAudioSession.CategoryOptions.defaultToSpeaker
            ])
            try session.setMode(.voiceChat)
            try session.setActive(true)
        } catch {
            print(error)
        }
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print(purchase.productId)
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
        }
    }


}

