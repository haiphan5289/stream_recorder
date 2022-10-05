//
//  VideoPreviewVC.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit
import AVKit
import Photos

class VideoPreviewVC: BaseVC {
    
    @IBOutlet weak var videoPlayView: VideoPlayView!
    @IBOutlet weak var closeButton: UIButton!
    
    var video: VideoModel?
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscapeLeft, .landscapeRight, .portrait]
    }
    
    private var auto: Bool = true
    
    lazy private(set) var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupViewAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.setupViewDisappear()
    }
    
    private func setupViewAppear() {
        if self.videoPlayView.assetViewVP == nil {
            view.addSubview(self.indicator)
            self.indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            self.indicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
            self.indicator.sizeToFit()
            self.indicator.startAnimating()

            guard let video = self.video else { return }
            getItem(video: video) { (item) in
                self.videoPlayView.assetViewVP = item
                self.indicator.stopAnimating()
                self.addGesture()
            }
        }
    }
    
    private func setupViewDisappear() {
        self.videoPlayView.assetViewVP = nil
        self.videoPlayView.playButton.isHidden = false
        self.videoPlayView.playButton.alpha = 1
        self.videoPlayView.playButton.isSelected = false
        self.clearFolder()
    }
    
    func clearFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    func getItem(video: VideoModel, completion: ((AVAsset?) -> Void)?) {
        let item = AVAsset(url: video.url)
        completion?(item)
    }
    
    func addGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapVideo(_:)))
        self.videoPlayView.addGestureRecognizer(gesture)
    }
    
    @objc func didTapVideo(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.videoPlayView.toggleControView(tapGesture: gesture)
        }
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    deinit {
        self.videoPlayView.stopVideo()
    }
    
}
