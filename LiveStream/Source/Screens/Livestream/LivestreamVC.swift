//
//  LivestreamVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class LivestreamVC: BaseVC {
    @IBOutlet weak var navigationView: NavigationBarView!
    @IBOutlet weak var framerateView: ParameterView!
    @IBOutlet weak var bitrateView: ParameterView!
    @IBOutlet weak var resolutionView: ParameterView!
    @IBOutlet weak var facebookView: PlatformView!
    @IBOutlet weak var twitterView: PlatformView!
    @IBOutlet weak var twitchView: PlatformView!
    @IBOutlet weak var rtmpView: PlatformView!
    @IBOutlet weak var tiktokView: PlatformView!
    @IBOutlet weak var youtubeView: PlatformView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupParameterView()
        self.setupPlatform()
        self.setupNavigationView()
    }
    
    private func setupNavigationView() {
        self.navigationView.didSelected = {
            self.navigationController?.popViewController(animated: true)
        }
        self.navigationView.title = "Livestream"
    }
    
    func setupParameterView() {
        let gestureResolution = UITapGestureRecognizer(target: self, action: #selector(didTapResolution(_:)))
        gestureResolution.numberOfTapsRequired = 1
        gestureResolution.cancelsTouchesInView = false
        self.resolutionView.addGestureRecognizer(gestureResolution)
        self.resolutionView.parameter = Cache.shared.resolution
        self.resolutionView.title = "Resolution"
        
        let gestureBitrate = UITapGestureRecognizer(target: self, action: #selector(didTapBitrate(_:)))
        gestureBitrate.numberOfTapsRequired = 1
        gestureBitrate.cancelsTouchesInView = false
        self.bitrateView.addGestureRecognizer(gestureBitrate)
        self.bitrateView.parameter = Cache.shared.bitrate
        self.bitrateView.title = "Bitrate"
        
        let gestureFramerate = UITapGestureRecognizer(target: self, action: #selector(didTapFramerate(_:)))
        gestureFramerate.numberOfTapsRequired = 1
        gestureFramerate.cancelsTouchesInView = false
        self.framerateView.addGestureRecognizer(gestureFramerate)
        self.framerateView.parameter = Cache.shared.frameRate
        self.framerateView.title = "Framerate"
        
    }
    
    func setupPlatform() {
        self.facebookView.platform = .Facebook
        self.facebookView.didSelected = {
            self.gotoSetupVC(type: .Facebook)
        }
        self.youtubeView.platform = .Youtube
        self.youtubeView.didSelected = {
            self.gotoSetupVC(type: .Youtube)
        }
        self.twitchView.platform = .Twitch
        self.twitchView.didSelected = {
            self.gotoSetupVC(type: .Twitch)
        }
        self.tiktokView.platform = .Tiktok
        self.tiktokView.didSelected = {
            self.gotoSetupVC(type: .Tiktok)
        }
        self.twitterView.platform = .Twitter
        self.twitterView.didSelected = {
            self.gotoSetupVC(type: .Twitter)
        }
        self.rtmpView.platform = .RTMP
        self.rtmpView.didSelected = {
            if !Cache.shared.premium && Cache.shared.lockFeature {
                let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true)
            } else {
                self.gotoSetupVC(type: .RTMP)
            }
        }
    }
    
    @objc func didTapResolution(_ tap: UITapGestureRecognizer) {
        self.present(configureAlert(type: .resolution), animated: true)
    }
    
    @objc func didTapBitrate(_ tap: UITapGestureRecognizer) {
        self.present(configureAlert(type: .bitrate), animated: true)
    }
    
    @objc func didTapFramerate(_ tap: UITapGestureRecognizer) {
        self.present(configureAlert(type: .framerate), animated: true)
    }
    
}

extension LivestreamVC {
    func configureAlert(type: VideoType) -> UIAlertController {
        let alertC = UIAlertController(title: "\n\n\n\n", message: nil, preferredStyle: UIAlertController.Style.actionSheet)

        let customView = UIView(frame: CGRect(x: 10.0, y: 10.0, width: alertC.view.bounds.size.width - 10.0 * 4.0, height: 80))
        let lbTitle = UILabel(frame: CGRect(
            x: 10,
            y: 10,
            width: alertC.view.bounds.size.width,
            height: 18)
        )
        lbTitle.center.x = customView.center.x
        lbTitle.text = type.title
        lbTitle.font = UIFont.setBold(size: 16)
        lbTitle.textAlignment = .center
        lbTitle.textColor = UIColor(hexString: "3C3C43", alpha: 0.6)
    
        let lbDescription = UILabel(frame: CGRect(
            x: 10, y: 35,
            width: alertC.view.bounds.size.width - 20,
            height: 41)
        )
        
        lbDescription.text = type.subTitle
        lbDescription.font = UIFont.setSemiBold(size: 12)
        lbDescription.textAlignment = .center
        lbDescription.textColor = UIColor(hexString: "3C3C43", alpha: 0.6)
        
        lbDescription.center.x = customView.center.x
        lbDescription.numberOfLines = .zero
        lbDescription.lineBreakMode = .byWordWrapping
        
        customView.backgroundColor = UIColor.clear
        customView.addSubview(lbTitle)
        customView.addSubview(lbDescription)
        alertC.view.addSubview(customView)
        
        type.data.forEach { item in
            let action = UIAlertAction(title: item, style: .default, handler: {(alert: UIAlertAction!) in
                switch type {
                case .bitrate:
                    self.bitrateView.parameter = item
                    Cache.shared.bitrate = item
                case .resolution:
                    self.resolutionView.parameter = item
                    Cache.shared.resolution = item
                case .framerate:
                    self.framerateView.parameter = item
                    Cache.shared.frameRate = item
                }
                
            })
            alertC.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
        alertC.addAction(cancelAction)
        return alertC
    }
    
    func gotoSetupVC(type: PlatformType) {
        let vc = initVC("LivestreamVC", storyID: "SetupLiveVC") as! SetupLiveVC
        vc.modalPresentationStyle = .overFullScreen
        vc.hidesBottomBarWhenPushed = true
        vc.typePlatForm = type
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
