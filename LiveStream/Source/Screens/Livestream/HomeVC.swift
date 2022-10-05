//
//  HomeVC.swift
//  LiveStream
//
//  Created by htv on 15/09/2022.
//

import UIKit

class HomeVC: BaseVC {
    
    @IBOutlet weak var titleView: TitleView!
    @IBOutlet weak var screenRecordImageView: UIImageView!
    @IBOutlet weak var liveStreamImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTitleView()
        self.setupImageView()
    }
    
    private func setupTitleView() {
        self.titleView.title = "Arcade Live"
        self.titleView.didTapCrown = {
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        }
        self.titleView.didTapSetting = {
            let vc = initVC("SettingVC") as! SettingVC
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func setupImageView() {
        let gestureScreen = UITapGestureRecognizer(target: self, action: #selector(didSelectScreenRecord(_:)))
        gestureScreen.numberOfTapsRequired = 1
        gestureScreen.cancelsTouchesInView = false
        self.screenRecordImageView.addGestureRecognizer(gestureScreen)
        self.screenRecordImageView.isUserInteractionEnabled = true
        
        let gestureLive = UITapGestureRecognizer(target: self, action: #selector(didSelectLiveStream(_:)))
        gestureLive.numberOfTapsRequired = 1
        gestureLive.cancelsTouchesInView = false
        self.liveStreamImageView.addGestureRecognizer(gestureLive)
        self.liveStreamImageView.isUserInteractionEnabled = true
    }
    
    @objc func didSelectScreenRecord(_ gesture: UITapGestureRecognizer) {
        let vc = initVC("ScreenRecordVC") as! ScreenRecordVC
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didSelectLiveStream(_ gesture: UITapGestureRecognizer) {
        let vc = initVC("LivestreamVC") as! LivestreamVC
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
