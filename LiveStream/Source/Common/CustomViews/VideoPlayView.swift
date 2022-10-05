//
//  VideoPlayView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import AVFoundation
import AVKit

private var ViewContextVideoPlay = 0

class VideoPlayView: UIView {
    
    public var playItemView: AVPlayerItem? {

        willSet {
            if self.playItemView == newValue {
                return
            }
            
            if let oldPlayItem = self.playItemView {
                self.removeObs(for: oldPlayItem)
                self.playView.pause()

                self.playView.replaceCurrentItem(with: nil)
            }

            if let newPlayerItem = newValue {
                self.playView.replaceCurrentItem(with: newPlayerItem)
                self.addObs(for: newPlayerItem)
            }
        }
    }
    
    var assetViewVP: AVAsset? {
        didSet {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            if self.assetViewVP == oldValue {
                return
            }
            
            if let oldAsset = oldValue {
                oldAsset.cancelLoading()
            }
            
            self.playItemView = nil
            
            if let newValue = self.assetViewVP {
                self.activityIndi.startAnimating()
                newValue.loadValuesAsynchronously(forKeys: ["duration", "tracks"], completionHandler: {
                    if newValue == self.assetViewVP {
                        var nserror: NSError?
                        let statusLoad = newValue.statusOfValue(forKey: "duration", error: &nserror)
                        var itemPlayer: AVPlayerItem?
                        if statusLoad == .loaded {
                            itemPlayer = AVPlayerItem(asset: newValue)
                        } else if statusLoad == .failed {
                            self.error = nserror
                        }
                        
                        DispatchQueue.main.async {
                            if newValue == self.assetViewVP {
                                self.activityIndi.stopAnimating()
                                
                                if let item = itemPlayer {
                                    self.playItemView = item
                                } else if let error = self.error, self.autoPlayOrShowError {
                                    self.showPlayError(error.localizedDescription)
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    public var beginPlayBlock: (() -> Void)?
    
    public var isControlHidden: Bool {
        get { return self.controlView.isHidden }
        
        set { self.controlView.isHidden = newValue }
    }
    
    public var isPlay: Bool {
        get { return self.playView.rate == 1.0 }
    }
        
    private var mediaPlay: Bool = false
    
    public var autoHides = true
    
    public var tapToToggle = true {
        willSet {
            self.tapGesture.isEnabled = newValue
        }
    }
    
    public var isFinished = false
    
    lazy var playButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        btn.setImage(UIImage(systemName: "pause.fill"), for: .selected)
        btn.titleLabel?.font = UIFont.setRegular(size: 24)
        btn.setTitleColor(UIColor(hexString: "75b9f2"), for: .normal)
        btn.setTitleColor(UIColor(hexString: "75b9f2"), for: .selected)
        btn.isSelected = false
        btn.alpha = 1
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(playAndHides), for: .touchUpInside)
        
        return btn
    }()
    
    lazy var durationLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.setMedium(size: 13)
        lbl.textColor = UIColor.black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        return lbl
    }()
    
    lazy var trackSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.thumbTintColor = .black
        slider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.11)
        slider.minimumTrackTintColor = UIColor.black
        let customThumb = Common.shared.makeCircleContext(size: CGSize(width: 16, height: 16), backgroundColor: .black)
        slider.setThumbImage(customThumb, for: .normal)
        slider.setThumbImage(customThumb, for: .highlighted)
        slider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTapped(tapGesture:))))
        slider.addTarget(self, action: #selector(timeSliderChange(sender:event:)), for: .valueChanged)
        return slider
    }()
    
    lazy var controlView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addShadow(
            radius: 0,
            maskCorner: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner],
            shadowColor: UIColor.black.withAlphaComponent(0.1),
            shadowOffset: CGSize(width: 0, height: -0.5),
            shadowRadius: 0,
            shadowOpacity: 10
        )
        view.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        view.layer.borderWidth = 0.5
        
        return view
    }()
    
    private let playPauseBut = UIButton(type: .custom)
    private var tapGesture: UITapGestureRecognizer!
    
    private lazy var activityIndi: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.isUserInteractionEnabled = false
        indicator.center = self.center
        indicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        
        return indicator
    }()
    
    private var avplayerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    private let playView = AVPlayer()
    
    private var currentTime: Double {
        get {
            return CMTimeGetSeconds(playView.currentTime())
        }
        
        set {
            guard let _ = self.playView.currentItem else { return }
            let newTime = CMTimeMakeWithSeconds(Double(Int64(newValue)), preferredTimescale: 1)
            self.playView.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
        
    private var autoPlayOrShowError = false
    
    private var _error: NSError?
    private var error: NSError? {
        get {
            return _error ?? self.playView.currentItem?.error as NSError?
        }
        
        set {
            _error = newValue
        }
    }
    
    private let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()

    private var timeObsToken: Any?
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var autoPlay: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupLayout()
    }
    
    deinit {
        guard let currentItem = self.playView.currentItem, currentItem.observationInfo != nil else { return }
        
        self.removeObs(for: currentItem)
    }
    
    @objc public func playAndHides() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.playButton.isSelected = !self.playButton.isSelected
            if self.isPlay {
                self.playButton.isHidden = false
            } else {
                self.playButton.isHidden = self.isControlHidden
            }
            self.playButton.alpha = self.playButton.isSelected ? 0.5 : 1
        }, completion: nil)
        
        if !self.isPlay {
            self.playVideo()
        } else {
            self.pauseVideo()
        }
        
        self.beginPlayBlock?()
    }
    
    public func playVideo() {
        guard !self.isPlay else { return }
        
        if let error = self.error {
            if let avAsset = self.assetViewVP ?? self.playItemView?.asset, self.isTriableErrorVP(error) {
                self.autoPlayOrShowError = true
                
                if avAsset is AVURLAsset {
                    self.assetViewVP = nil
                } else {
                    self.assetViewVP = avAsset
                }
                self.error = nil
            } else {
                self.showPlayError(error.localizedDescription)
            }
            
            return
        }
        
        if let currentItem = self.playItemView {
            if currentItem.status == .readyToPlay {
                if self.isFinished {
                    self.isFinished = false
                    self.currentTime = 0.0
                }
                
                self.playView.play()
                
                self.updateactivityStateIfNeeded()
            } else if currentItem.status == .unknown {
                self.playView.play()
            }
        }
    }
    
    @objc public func pauseVideo() {
        guard let _ = self.playView.currentItem, self.isPlay else { return }
        
        self.playView.pause()
    }
    
    public func stopVideo() {
        self.assetViewVP?.cancelLoading()
        self.pauseVideo()
    }
    
    public func resetVideo() {
        self.assetViewVP?.cancelLoading()
        
        self.assetViewVP = nil
        self.playItemView = nil
        self.error = nil
        
        self.autoPlayOrShowError = false
        self.isFinished = false
        self.activityIndi.stopAnimating()
        
        self.playButton.isHidden = false
        
        self.playPauseBut.isEnabled = false
        self.trackSlider.isEnabled = false
        self.trackSlider.value = 0
        
        self.durationLabel.isEnabled = false
        self.durationLabel.text = "00:00"
    }
    
    // MARK: - Private
    private func setupLayout() {
        self.avplayerLayer.player = self.playView
        
        self.addSubview(self.activityIndi)
        self.addSubview(controlView)
        controlView.addSubview(playButton)
        controlView.addSubview(durationLabel)
        controlView.addSubview(trackSlider)

        NSLayoutConstraint.activate([
            controlView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            controlView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            controlView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            controlView.heightAnchor.constraint(equalToConstant: 38),

            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),
            playButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: 0),
            playButton.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 7),
            
            trackSlider.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 7),
            trackSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -12),
            trackSlider.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: 0),

            durationLabel.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: 0),
            durationLabel.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -12)
        ])
        controlView.isHidden = self.isControlHidden
    }
    
    @objc private func timeSliderChange(sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                mediaPlay = self.isPlay
                if mediaPlay {
                    self.pauseVideo()
                }
                break
            case .moved:
                self.currentTime = Double(self.trackSlider.value)
            case .ended,
                 .cancelled:
                if mediaPlay {
                    self.playVideo()
                }
            default:
                break
            }
        } else {
            self.currentTime = Double(self.trackSlider.value)
            self.playVideo()
        }
    }
    
    @objc private func sliderTapped(tapGesture: UITapGestureRecognizer) {
        if let slider = tapGesture.view as? UISlider {
            if slider.isHighlighted { return }
            
            let point = tapGesture.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * Float(slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: false)
            slider.sendActions(for: .valueChanged)
        }
    }
    
    @objc public func toggleControView(tapGesture: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.isControlHidden = !self.isControlHidden
            if self.isPlay {
                self.playButton.isHidden = self.isControlHidden
            } else {
                self.playButton.isHidden = false
            }
            self.playButton.alpha = self.playButton.isSelected ? 0.5 : 1
        }, completion: nil)
        
//        self.startHidesControlTimerIfNeeded()
    }

    private var hideControlTimer: Timer?
    private func startHidesControlNeeded() {
        guard self.autoHides else { return }
        
        self.stopHidesTimer()
        if !self.isControlHidden && self.isPlay {
            self.hideControlTimer = Timer.scheduledTimer(timeInterval: 5,
                                                              target: self,
                                                              selector: #selector(hidesControlNeeded),
                                                              userInfo: nil,
                                                              repeats: false)
        }
    }
    
    private func stopHidesTimer() {
        guard self.autoHides else { return }
        
        self.hideControlTimer?.invalidate()
        self.hideControlTimer = nil
    }
    
    @objc private func hidesControlNeeded() {
        if self.isPlay {
            self.isControlHidden = true
        }
    }
    
    private func createStringTime(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeFormatter.string(from: components as DateComponents)!
    }
    
    private func showPlayError(_ message: String) {
        // Show toast message
        print(message)
    }
    
    private func isTriableErrorVP(_ error: NSError) -> Bool {
        let untriableCodes: Set<Int> = [
            URLError.badURL.rawValue,
            URLError.fileDoesNotExist.rawValue,
            URLError.unsupportedURL.rawValue,
        ]
        
        return !untriableCodes.contains(error.code)
    }
    
    private func updateactivityStateIfNeeded() {
        if self.isPlay, let currentItem = self.playView.currentItem {
            if currentItem.isPlaybackBufferEmpty {
                self.activityIndi.startAnimating()
            } else if currentItem.isPlaybackLikelyToKeepUp {
                self.activityIndi.stopAnimating()
            } else {
                self.activityIndi.stopAnimating()
            }
        }
    }
    
    // MARK: - Observer
    
    private func addObs(for playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.new, .initial], context: &ViewContextVideoPlay)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: &ViewContextVideoPlay)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new, .initial], context: &ViewContextVideoPlay)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new, .initial], context: &ViewContextVideoPlay)
        playView.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new, .initial], context: &ViewContextVideoPlay)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let interval = CMTime(value: 1, timescale: 1)
        self.timeObsToken = playView.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            if strongSelf.isPlay {
                strongSelf.trackSlider.value = timeElapsed
            }
        })
    }
    
    private func removeObs(for playerItem: AVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &ViewContextVideoPlay)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &ViewContextVideoPlay)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &ViewContextVideoPlay)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &ViewContextVideoPlay)
        self.playView.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: &ViewContextVideoPlay)
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserverToken = self.timeObsToken {
            self.playView.removeTimeObserver(timeObserverToken)
            self.timeObsToken = nil
        }
    }
    
    @objc func itemDidPlayToEnd(notification: Notification) {
        if (notification.object as? AVPlayerItem) == self.playView.currentItem {
            self.isFinished = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
                self.playButton.isHidden = false
                self.playButton.alpha = 1
                self.playButton.isSelected = false
            }, completion: nil)
        }
    }
    
    // Update our UI when player or `player.currentItem` changes.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &ViewContextVideoPlay else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.duration) {
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            } else {
                newDuration = CMTime.zero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(playView.currentTime())) : 0.0
            
            self.trackSlider.maximumValue = Float(newDurationSeconds)
            self.trackSlider.value = currentTime
            
            self.playPauseBut.isEnabled = hasValidDuration
            self.trackSlider.isEnabled = hasValidDuration
            
            self.durationLabel.isEnabled = hasValidDuration
            self.durationLabel.text = self.createStringTime(time: Float(newDurationSeconds))
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            guard let currentItem = object as? AVPlayerItem else { return }
            guard self.autoPlayOrShowError else { return }
            
            let newStatus: AVPlayerItem.Status
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            
            if newStatus == .readyToPlay {
                self.playVideo()
                
                self.autoPlayOrShowError = false
            } else if newStatus == .failed {
                if let error = currentItem.error {
                    self.showPlayError(error.localizedDescription)
                } else {
                    self.showPlayError("Unknown")
                }
                
                self.autoPlayOrShowError = false
            }
        } else if keyPath == #keyPath(AVPlayer.rate) {
            // Update UI status.
            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            
            if newRate == 1.0 {
//                self.startHidesControlTimerIfNeeded()
                self.playPauseBut.isSelected = true
            } else {
//                self.stopHidesControlTimer()
                self.playPauseBut.isSelected = false
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            self.updateactivityStateIfNeeded()
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            self.updateactivityStateIfNeeded()
        }
    }
}

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}
