//
//  SetupLiveVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit
import ReplayKit

class SetupLiveVC: BaseVC {
    
    @IBOutlet weak var navigationBarView: NavigationBarView!
    @IBOutlet weak var keyTextField: CustomTextField!
    @IBOutlet weak var urlTextField: CustomTextField!
    @IBOutlet weak var screenBroadcastButton: UIButton!
    @IBOutlet weak var liveCameraButton: UIButton!
    @IBOutlet weak var linkKeyLabel: UILabel!
    
    var typePlatForm: PlatformType = .Facebook
    
    lazy var broadcastPickerView: RPSystemBroadcastPickerView = {
        let view = RPSystemBroadcastPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.preferredExtension = "com.recordscreen1.Broadcast-LiveStream"
        view.backgroundColor = .clear
        
        if let button = view.subviews.first as? UIButton {
            button.fillSuperView()
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .selected)
        }
        
        return view
    }()
    
    let userDefaultBroadcast = UserDefaults(suiteName: "group.com.recordscreen11")
    lazy var notifiCenter: NotificationCenter = .default
    var valueObserver: NSKeyValueObservation?
    var objProtocol: [NSObjectProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupBroadcastRecorder()
        
        valueObserver = userDefaultBroadcast?.observe(\.broadcast, options: [.initial, .new], changeHandler: { userDefaults, valueChange in
            if let value = valueChange.newValue {
                if value == 1 {
                } else {
                    self.saveFile()
                }
            }
        })
        self.keyTextField.text = "live_789340917_gxglf47jOloRKz75Zyr1dCAkGH5Fba"
        self.urlTextField.text = "rtmp://sin04.contribute.live-video.net/app/"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        objProtocol.append(
            notifiCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: { [weak self] _ in
                self?.saveFile()
            })
        )
    }
    
    private func setupUI() {
        self.navigationBarView.didSelected = {
            self.navigationController?.popViewController(animated: true)
        }
        self.linkKeyLabel.underline()
        self.navigationBarView.title = self.typePlatForm.title
    }
    
    private func setupBroadcastRecorder() {
        self.view.addSubview(self.broadcastPickerView)
        NSLayoutConstraint.activate([
            self.broadcastPickerView.leadingAnchor.constraint(equalTo: self.screenBroadcastButton.leadingAnchor),
            self.broadcastPickerView.topAnchor.constraint(equalTo: self.screenBroadcastButton.topAnchor),
            self.broadcastPickerView.trailingAnchor.constraint(equalTo: self.screenBroadcastButton.trailingAnchor),
            self.broadcastPickerView.bottomAnchor.constraint(equalTo: self.screenBroadcastButton.bottomAnchor)
        ])
    }
    
    private func configureLive() {
        if let url = self.urlTextField.text, let key = self.keyTextField.text {
            Cache.shared.url = url
            Cache.shared.key = key
        } else {
            Alert.shared.showAlert(title: "Error", message: "Please fill in all fields ", rootVC: self)
        }
    }
    
    @IBAction func didTapScreenBroadcast(_ sender: Any) {
        if !Cache.shared.premium && Cache.shared.lockAllFeature {
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        } else {
            self.configureLive()
            if let button = self.broadcastPickerView.subviews.first as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
        }
    }
    @IBAction func didTapLiveCamera(_ sender: Any) {
        if !Cache.shared.premium && Cache.shared.lockAllFeature {
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        } else {
            self.configureLive()
            let liveCameraVC = initVC("LivestreamVC", storyID: "LiveCameraVC")
            liveCameraVC.modalPresentationStyle = .overFullScreen
            liveCameraVC.hidesBottomBarWhenPushed = true
            self.present(liveCameraVC, animated: true)
        }
        
    }
    
    deinit {
        valueObserver?.invalidate()
    }
    
    private func saveFile() {
        let fileManager = FileManager.default
        if let container = fileManager
                .containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.metaic.screenrecorder"
                )?.appendingPathComponent("Library/Documents/") {

            let documentsDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: container.path)
                for path in contents {
                    guard !path.hasSuffix(".plist") else {
                        print("file at path \(path) is plist, exiting")
                        return
                    }
                    let fileURL = container.appendingPathComponent(path)
                    var isDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
                        return
                    }
                    guard !isDirectory.boolValue else {
                        return
                    }
                    let destinationURL = documentsDirectory.appendingPathComponent(path)
                    do {
                        try fileManager.copyItem(at: fileURL, to: destinationURL)
                        print("Successfully copied \(fileURL)", "to: ", destinationURL)
                        NotificationCenter.default.post(name: NSNotification.Name("did_record_video"), object: nil, userInfo: nil)
                    } catch {
                        print("error copying \(fileURL) to \(destinationURL)", error)
                    }
                }
            } catch {
                print("contents, \(error)")
            }
        }
    }
    
}
