//
//  VideoRecordSlider.swift
//  xrecorder
//
//  Created by Huy on 15/03/2022
//

import UIKit

public protocol VideoRecordSliderDelegate {
    func didChangeValue(videoRangeSlider: VideoRecordSlider, startTime: Float64, endTime: Float64)
    func indicatorDidChangePosition(videoRangeSlider: VideoRecordSlider, position: Float64)

     func sliderGesturesBegan()
     func sliderGesturesEnded()
}

//public @objc protocol VideoRecordSliderDelegate: AnyObject {
//    func didChangeValue(videoRangeSlider: VideoRecordSlider, startTime: Float64, endTime: Float64)
//    func indicatorDidChangePosition(videoRangeSlider: VideoRecordSlider, position: Float64)
//
//    @objc optional func sliderGesturesBegan()
//    @objc optional func sliderGesturesEnded()
//}

public class VideoRecordSlider: UIView {
    private enum DragHandleChoice {
        case start
        case end
    }
    
    public var delegate: VideoRecordSliderDelegate?
    
    var progressIndicator   = ProgressIndicator()
    var progressBar         = UIView()
    var startTimeView       = TimeView()
    var endTimeView         = TimeView()
    
    let thumbnailsManager   = ThumbnailsManager()
    var duration: Float64   = 0.0
    var videoURL            = URL(fileURLWithPath: "")
    
    public var currentSecond: Float64 {
        return secondsFromValue(value: progressPercentage)
    }
    var progressPercentage: Float64 = 0
    var endPercentage: Float64 = 0
    var startX: CGFloat = 0
    
    var isProgressIndicatorDraggable: Bool = true
    
    var isUpdatingThumbnails = false
    var isReceivingGesture: Bool = false
    public var isRecording: Bool = false
    
    private let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background, target: nil)
    
    private var progressIndicatorWidth: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 50 : 30
    }
    private var timeViewWidth: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 80 : 60
    }
    private var timeViewHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 45 : 25
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup(){
        self.isUserInteractionEnabled = true
        layoutIfNeeded()
        
        // Setup Progress bar
        progressBar = UIView(frame: CGRect(x: 0,
                                         y: 0,
                                         width: 0,
                                         height: self.frame.size.height))
        progressBar.backgroundColor = .red
        self.addSubview(progressBar)

        self.addObserver(self,
                         forKeyPath: "bounds",
                         options: NSKeyValueObservingOptions(rawValue: 0),
                         context: nil)

        // Setup Progress Indicator
        let progressDrag = UIPanGestureRecognizer(target:self,
                                                  action: #selector(progressDragged(recognizer:)))
        progressDrag.delaysTouchesBegan = true
        progressDrag.delaysTouchesEnded = true
        progressDrag.minimumNumberOfTouches = 0
        progressDrag.maximumNumberOfTouches = 1
        progressIndicator = ProgressIndicator(frame: CGRect(x: 0,
                                                              y: 0,
                                                              width: progressIndicatorWidth,
                                                              height: self.frame.size.height))
        progressIndicator.addGestureRecognizer(progressDrag)
        self.addSubview(progressIndicator)

        // Setup time labels
        startTimeView = TimeView(size: CGSize(width: timeViewWidth, height: timeViewHeight), position: self.frame.height)
        startTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(startTimeView)

        endTimeView = TimeView(size: CGSize(width: timeViewWidth, height: timeViewHeight), position: 0)
        endTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(endTimeView)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds"{
            self.updateThumbnails()
        }
    }
    
    // MARK: Public functions

    public func setProgressIndicatorImage(image: UIImage){
        self.progressIndicator.imageView.image = image
    }

    public func updateProgressIndicator(seconds: Float64){
        if !isReceivingGesture {
            if seconds >= duration {
//                self.resetProgressPosition()
                self.progressPercentage = self.valueFromSeconds(seconds: duration)
            } else {
                self.progressPercentage = self.valueFromSeconds(seconds: seconds)
            }

            layoutSubviews()
        }
    }

    public func setVideoURL(videoURL: URL){
        self.duration = VideoHelper.videoDuration(videoURL: videoURL)
        self.endPercentage = valueFromSeconds(seconds: duration)
        self.videoURL = videoURL
        self.superview?.layoutSubviews()
        self.updateThumbnails()
    }

    public func updateThumbnails(){
        if !isUpdatingThumbnails{
            self.isUpdatingThumbnails = true
            backgroundQueue.async {
                _ = self.thumbnailsManager.updateThumbnails(view: self, videoURL: self.videoURL, duration: self.duration)
                self.isUpdatingThumbnails = false
            }
        }
    }
    
    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc func progressDragged(recognizer: UIPanGestureRecognizer){
        if duration == 0 || isRecording || !isProgressIndicatorDraggable {
            return
        }
        
        startX = progressIndicator.frame.midX - 5
        
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(value: 0)
        let positionLimitEnd    = positionFromValue(value: 100)

        var position = positionFromValue(value: self.progressPercentage)
        position = position + translation.x

        if position < positionLimitStart {
            position = positionLimitStart
        }

        if position > positionLimitEnd {
            position = positionLimitEnd
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        progressIndicator.center = CGPoint(x: position , y: progressIndicator.center.y)

        let percentage = progressIndicator.center.x * 100 / self.frame.width

        let progressSeconds = secondsFromValue(value: progressPercentage)

        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)

        self.progressPercentage = Float64(percentage)

        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: Float64) -> CGFloat {
        let position = CGFloat(value) * self.frame.size.width / 100
        return position
    }
    
    private func secondsFromValue(value: Float64) -> Float64 {
        return duration * (value / 100)
    }

    private func valueFromSeconds(seconds: Float64) -> Float64 {
        return (seconds * 100) / duration
    }
    
    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            
            self.isReceivingGesture = true
            self.delegate?.sliderGesturesBegan()
            
        } else if recognizer.state == .ended {
            
            self.isReceivingGesture = false
            self.delegate?.sliderGesturesEnded()
        }
    }
    
    public func resetProgressPosition() {
        self.progressPercentage = 0
        self.startX = 0
        let progressPosition = positionFromValue(value: self.progressPercentage)
        progressIndicator.center = CGPoint(x: progressPosition , y: progressIndicator.center.y)
        
        let startSeconds = secondsFromValue(value: self.progressPercentage)
        self.delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: startSeconds)
        layoutSubviews()
    }
    
    public func resetProgressBar() {
        self.startX = progressIndicator.frame.midX - 5
        layoutSubviews()
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        startTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.progressPercentage))
        endTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.endPercentage))

        let progressPosition = positionFromValue(value: self.progressPercentage)

        progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)

        progressBar.frame = CGRect(x: startX,
                               y: 0,
                               width: progressIndicator.frame.midX - 5 - startX,
                               height: self.frame.height)

        // Update time view
        startTimeView.center = CGPoint(x: progressIndicator.center.x, y: startTimeView.center.y)
        endTimeView.center = CGPoint(x: self.frame.width, y: endTimeView.center.y)
    }

    private func secondsToFormattedString(totalSeconds: Float64) -> String{
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }

    deinit {
       removeObserver(self, forKeyPath: "bounds")
    }
}

extension VideoRecordSlider: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if !(otherGestureRecognizer is UIPanGestureRecognizer) {
            return true
        } else {
            return false
        }
    }
}
