//
//  ScreenRecordVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit
import AVKit
import ReplayKit

class ScreenRecordVC: BaseVC {
    
    @IBOutlet weak var navigationView: NavigationBarView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var recordImageView: UIImageView!
    
    var state: ScreenRecordState = .start
    var timer: Countdown?
    
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
        self.setupNavigationView()
        self.setupRecord()
        valueObserver = userDefaultBroadcast?.observe(\.broadcast, options: [.initial, .new], changeHandler: { userDefaults, valueChange in
            if let value = valueChange.newValue {
                if value == 1 {
                    self.start()
                } else {
                    self.stop()
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.objProtocol.append(
            self.notifiCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil, using: { [weak self] _ in
                self?.saveFile()
            })
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.objProtocol.forEach(self.notifiCenter.removeObserver(_:))
    }
    
    private func setupNavigationView() {
        self.navigationView.didSelected = {
            self.navigationController?.popViewController(animated: true)
        }
        self.navigationView.title = "Screen Recorder"
    }
    
    private func setupUI() {
        self.recordImageView.image = self.state.image
        self.timeLabel.text = "00:00:00"
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapRecord(_:)))
        gesture.numberOfTapsRequired = 1
        gesture.cancelsTouchesInView = false
        self.recordImageView.addGestureRecognizer(gesture)
    }
    
    @objc func didTapRecord(_ tap: UIGestureRecognizer) {
        if !Cache.shared.premium && Cache.shared.lockAllFeature {
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        } else {
            if let button = self.broadcastPickerView.subviews.first as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
        }
    }
    
    private func setupRecord() {
        self.view.addSubview(self.broadcastPickerView)
        NSLayoutConstraint.activate([
            self.broadcastPickerView.leadingAnchor.constraint(equalTo: self.recordImageView.leadingAnchor),
            self.broadcastPickerView.topAnchor.constraint(equalTo: self.recordImageView.topAnchor),
            self.broadcastPickerView.trailingAnchor.constraint(equalTo: self.recordImageView.trailingAnchor),
            self.broadcastPickerView.bottomAnchor.constraint(equalTo: self.recordImageView.bottomAnchor)
        ])
    }
    
    internal func start() {
        if self.state == .start {
            self.timer = Countdown()
            self.timer?.startCountdown(beginingValue: 0, interval: 1, countDown: true)
            self.timer?.delegate = self
            self.state = .stop
            self.recordImageView.image = self.state.image
            self.broadcastPickerView.isHidden = true
        }
    }
    
    private func stop() {
        if self.state == .stop {
            self.timer?.pauseCountdown()
            self.state = .start
            self.timeLabel.text = "00:00:00"
            self.recordImageView.image = self.state.image
            self.broadcastPickerView.isHidden = false
            self.saveFile()
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

extension ScreenRecordVC: CountdownDelegate {
    func updateCounterValue(newValue: Int) {
        print(newValue)
    }
    
    func updateCounterValue(newValueString: String) {
        
        print(newValueString)
        self.timeLabel.text = newValueString
    }
    
    func pause() {
        self.timer = nil
        self.state = .start
        self.recordImageView.image = self.state.image
    }
    
    func resume() {
    }
    
    func end() {
    }
}
