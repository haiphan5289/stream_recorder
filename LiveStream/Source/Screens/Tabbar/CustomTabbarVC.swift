//
//  CustomTabbarVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class CustomTabbarVC: UITabBarController, UITabBarControllerDelegate {
    
    var index: Int = 0 {
        didSet {
            self.selectedIndex = index
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createTabbar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupHeight()
    }
    
    private func createTabbar() {
        let liveStreamVC = initVC("LivestreamVC", storyID: "HomeVC") as! HomeVC
        liveStreamVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "ic_livestream"), selectedImage: UIImage(named: "ic_livestream_select"))
        let liveStreamNavC = UINavigationController(rootViewController: liveStreamVC)
        let myRecordsVC = initVC("MyRecordsVC") as! MyRecordsVC
        myRecordsVC.tabBarItem = UITabBarItem(title: "Album", image: UIImage(named: "ic_my_record"), selectedImage: UIImage(named: "ic_my_record_select"))
        let myRecordsNavC = UINavigationController(rootViewController: myRecordsVC)
        let videoToolVC = initVC("VideoToolVC") as! VideoToolVC
        videoToolVC.tabBarItem = UITabBarItem(title: "Tool", image: UIImage(named: "ic_video_tool"), selectedImage: UIImage(named: "ic_video_tool_select"))
        let videoToolNavC = UINavigationController(rootViewController: videoToolVC)
        
        self.viewControllers = [liveStreamNavC, videoToolNavC, myRecordsNavC]
        
        self.delegate = self
        self.tabBar.unselectedItemTintColor = .white.withAlphaComponent(0.5)
        self.tabBar.tintColor = UIColor(hexString: "#FF5B39")
        self.tabBar.unselectedItemTintColor = UIColor(hexString: "#C1C1C1")
        //self.tabBar.backgroundColor = UIColor(hexString: "4738DC")
    }
    
    private func setupHeight() {
        let height = 80.0 * heightScreen/812
        self.tabBar.frame.size.height = height
        self.tabBar.frame.origin.y = view.frame.height - height
        self.tabBar.clipsToBounds = true
        self.tabBar.borderColor = UIColor(hexString: "#707070").withAlphaComponent(0.3)
        self.tabBar.borderWidth = 0.5
//        self.tabBar.layer.cornerRadius = 16
//        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}
