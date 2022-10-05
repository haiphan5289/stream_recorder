//
//  Application.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class Application {
    static let shared = Application()
    private var window: UIWindow?
    private var tabBarVC: CustomTabbarVC?
    
    func configureMain(window: UIWindow?) {
        let rootVC = initVC("RootVC") as! RootVC
        let navigationC = UINavigationController(rootViewController: rootVC)
        window?.rootViewController = navigationC
        window?.makeKeyAndVisible()
        self.window = window
    }
    
    func gotoVC(vc: UIViewController) {
        let navigationC = UINavigationController(rootViewController: vc)
        self.window?.rootViewController = navigationC
        self.window?.makeKeyAndVisible()
    }
    
    func gotoTabbar(index: Int = 0) {
        if self.tabBarVC == nil {
            self.tabBarVC = CustomTabbarVC()
        }
        self.tabBarVC?.index = index
        self.window?.rootViewController = self.tabBarVC
        self.window?.makeKeyAndVisible()
    }
}
