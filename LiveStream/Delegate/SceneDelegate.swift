//
//  SceneDelegate.swift
//  LiveStream
//
//  Created by htv on 09/08/2022.
//

import UIKit
import SwiftyStoreKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: scene)
        Application.shared.configureMain(window: self.window)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if !Cache.shared.premium {
            return
        }
        self.verify(env: .production)
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    func verify(env: AppleReceiptValidator.VerifyReceiptURLType) {
        let inappHelper = IAPHelper()
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: inappHelper.sercetKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: [inappHelper.week, inappHelper.month, inappHelper.year], inReceipt: receipt)
                    
                switch purchaseResult {
                case .purchased(_, _):
                    Cache.shared.premium = true
                case .notPurchased:
                    Cache.shared.premium = false
                    return
                case .expired(expiryDate: _, items: _):
                    if env == .production {
                        self.verify(env: .sandbox)
                    } else {
                        Cache.shared.premium = false
                    }
                }
            case .error(let error):
                if env == .production {
                    self.verify(env: .sandbox)
                }
            }
        }
    }

}

