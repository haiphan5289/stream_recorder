//
//  FacecamVC.swift
//  stream_recorder
//
//  Created by HHumorous on 14/04/2022.
//

import AVFoundation
import UIKit
import CocoaLumberjack
import Toaster
import Photos
import PixelSDK
import SwiftOverlays
import FaceCamFW


class FaceCamVC: UIViewController {
    @IBOutlet weak var videoRecordView: UIView!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    @IBOutlet weak var contentVideo: UIView!
    
    private let videoRangeSlider: VideoRecordSlider = VideoRecordSlider()
    
    var videoURL: URL?
    private var isVideoInited: Bool = false
    
    var alertController: UIAlertController?
    var streamer: StreamerFacecamManager?
    
    var fullLayer: AVCaptureVideoPreviewLayer?
    lazy var fullLayerImage: CameraPreviewLayer = {
        return CameraPreviewLayer()
    }()
    
    var dragZoneView: UIView?
    var pipLayer: AVCaptureVideoPreviewLayer?
    lazy var pipResizeView: OTResizableView = {
        let view = OTResizableView(contentView: pipLayerImage)
        view.keepAspectEnabled = true
        view.minimumAspectScale = 3
        
        return view
    }()
    lazy var pipLayerImage: CameraPreviewLayer = {
        return CameraPreviewLayer(frame: CGRect(x: 0, y: 0, width: 100, height: 150))
    }()
    var resizableFrame: CGRect?
    var isAdjustPipPos: Bool = false
    
//    var cloudUtils = CloudUtilites()
    var videoRecordURL: URL?
    
    override open var shouldAutorotate : Bool {
        get {
            return false
        }
    }
    
    // MARK: StreamViewController state transition
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainView = self
        
        //This is important
        //Create FW and create View = code, donot must use sotryboard
        // App will creash with bug "exc_bad_access (code=2, address=0x1f3cb31e0)" && exc_bad_instruction
        contentVideo.addSubview(videoRangeSlider)
        videoRangeSlider.translatesAutoresizingMaskIntoConstraints = false
        videoRangeSlider.topAnchor.constraint(equalTo: contentVideo.topAnchor).isActive = true
        videoRangeSlider.leftAnchor.constraint(equalTo: contentVideo.leftAnchor).isActive = true
        videoRangeSlider.rightAnchor.constraint(equalTo: contentVideo.rightAnchor).isActive = true
        videoRangeSlider.bottomAnchor.constraint(equalTo: contentVideo.bottomAnchor).isActive = true
        self.displayUI()
        self.recordButtonUI(state: 0)
        self.videoRangeSlider.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIDevice.current.isBatteryMonitoringEnabled = true
        // Handle "Back" from Settings page or first app launch
        if deviceAuthorized {
            startCapture()
        } else {
            checkForAuthorizationStatus()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DLog("viewWillDisappear")
        
//        ToastCenter.default.cancelAll()
        dismissAlertController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DLog("viewDidDisappear")
        stopCapture()
    }
    
    @IBAction func didTapRecord(_ sender: UIButton) {
        if sender.tag == 0 {
            startRecord()
        } else if sender.tag == 2 {
            stopRecord()
        } else if sender.tag == 3,
                  let fileURL = videoRecordURL {
//            if !cloudUtils.deleteVideo(fileUrl: fileURL, from: .local) {
//                DLog("Delete video error")
//            }
            recordButtonUI(state: 0)
            videoRangeSlider.resetProgressBar()
            videoRecordURL = nil
        }
    }
    
    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func didTabSave(_ sender: Any) {
        if let recordURL = videoRecordURL {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: recordURL)
            }) { saved, error in
                if saved {
                    DispatchQueue.main.async {
                        self.recordButtonUI(state: 0)
                        self.videoRangeSlider.resetProgressBar()
                        Toast(text: "Done", duration: Delay.long).show()
                        self.dismiss(animated: true)
                    }
                }
            }
        } else {
            Toast(text: "Please record video first!", duration: Delay.long).show()
        }
        
    }
    
    private func initVideo() {
        if let videoURL = self.videoURL {
            if !isVideoInited {
                isVideoInited = true
                streamer?.initVideo(videoURL)
                videoRangeSlider.setVideoURL(videoURL: videoURL)
                recordButtonUI(state: 0)
                videoRangeSlider.resetProgressPosition()
                videoRangeSlider.resetProgressBar()
            } else {
                streamer?.initVideo(videoURL)
                streamer?.player?.seek(to: CMTime(seconds: videoRangeSlider.currentSecond, preferredTimescale: 1000))
                isAdjustPipPos = !isAdjustPipPos
            }
        }
    }
    
    // MARK: Capture utitlies
    
    /* Note: method is called on a background thread after permission request. Move your UI update codes inside the main queue. */
    func startCapture() {
        DLog("StreamViewController::startCapture")
        do {
            removePreview()
            DispatchQueue.main.async {
               // UIApplication.shared.isIdleTimerDisabled = true
            }
            if streamer == nil {
                streamer = StreamerFacecamManager(postprocess: Settings.sharedInstance.postprocess)
            }
            streamer?.delegate = self
            streamer?.videoConfig = Settings.sharedInstance.videoConfig
            streamer?.audioConfig = Settings.sharedInstance.audioConfig
            initVideo()
            try streamer?.startCapture(preferredInput: Settings.sharedInstance.preferredInput,
                                       mode: Settings.sharedInstance.videoStabilizationMode,
                                       startAudio: true,
                                       startVideo: true)
        } catch {
            DLog("can't start capture: \(error.localizedDescription)")
        }
    }
    
    func stopCapture() {
        DLog("StreamViewController::stopCapture")
        
        NotificationCenter.default.removeObserver(self)
       // UIApplication.shared.isIdleTimerDisabled = false
        
        streamer?.stopCapture()
        streamer = nil
    }
    
    func onCaptureFailed(message: String) {
        stopCapture()
        removePreview()
    }
    
    func removePreview() {
        fullLayer?.removeFromSuperlayer()
        fullLayer = nil
        pipLayer?.removeFromSuperlayer()
        pipLayer = nil
        
        fullLayerImage.removeFromSuperview()
        
        dragZoneView?.removeFromSuperview()
        dragZoneView = nil
        
        pipResizeView.removeFromSuperview()
    }
    
    func releaseConnection(id: Int32) {
        if id != -1 {
            DLog("SwiftApp::release connection: \(id)")
        }
    }
    
    // Method is called on a background thread. Move UI update code inside the main queue.
//    func connectionStateDidChange(id: Int32, state: ConnectionStatus, status: ConnectionStatus, info: [AnyHashable:Any]!) {
//        DispatchQueue.main.async {
//            self.onConnectionStateChange(id: id, state: state, status: status, info: info)
//        }
//    }
//
//    func onConnectionStateChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
//        DLog("connectionStateDidChange id:\(id) state:\(state.rawValue) status:\(status.rawValue)")
//
//        // ignore disconnect confirmation after releaseConnection call
//
//    }
    
    // MARK: mp4 record
    func startRecord() {
        streamer?.startRecord()
    }
    
    func stopRecord() {
        streamer?.stopRecord(restart: false)
    }
    
    // MARK: Can't change camera
    func notification(notification: StreamerNotification) {
        switch (notification) {
        case .ActiveCameraDidChange:
            DispatchQueue.main.async {
                self.updatePreviewOrientation()
            }
        case .ChangeCameraFailed:
            DispatchQueue.main.async {
                let message = NSLocalizedString("The selected video size or frame rate is not supported by the destination camera. Decrease the video size or frame rate before switching cameras.", comment: "")
                Toast(text: message, duration: Delay.long).show()
            }
        case .FrameRateNotSupported:
            DispatchQueue.main.async {
                let message = (Settings.sharedInstance.cameraPosition == .front) ?
                    NSLocalizedString("The selected frame rate is not supported by this camera. Try to start app with Back Camera.", comment: "") :
                    NSLocalizedString("The selected frame rate is not supported by this camera.", comment: "")
                Toast(text: message, duration: Delay.long).show()
            }
        }
    }
    
    // MARK: Device orientation
    @objc func orientationDidChange(notification: Notification) {
        DLog("orientationDidChange")
        updateOrientation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(
            alongsideTransition: nil,
            completion: { [weak self] _ in
                self?.updateOrientation()
            }
        )
    }
    
    // 1 - Set the preview layer frame so that the frame of the preview layer changes when the screen rotates.
    // 2 - Rotate the preview layer connection with the rotation of the device.
    func updateOrientation() {
        DLog("updateOrientation")
        videoRangeSlider.resetProgressBar()
        
        let deviceOrientation = UIApplication.shared.statusBarOrientation
        let newOrientation = toAVCaptureVideoOrientation(deviceOrientation: deviceOrientation, defaultOrientation: AVCaptureVideoOrientation.portrait)
//        if fullLayer?.connection?.isVideoOrientationSupported ?? false {
//            fullLayer?.connection?.videoOrientation = newOrientation
//        }
        if pipLayer?.connection?.isVideoOrientationSupported ?? false {
            pipLayer?.connection?.videoOrientation = newOrientation
        }
        
        if Settings.sharedInstance.postprocess {
            if Settings.sharedInstance.liveRotation {
                streamer?.orientation = newOrientation
            }
        }
    }
    
    func toAVCaptureVideoOrientation(deviceOrientation: UIInterfaceOrientation, defaultOrientation: AVCaptureVideoOrientation) -> AVCaptureVideoOrientation {
        
        var captureOrientation: AVCaptureVideoOrientation
        
        switch (deviceOrientation) {
        case .portrait:
            // Device oriented vertically, home button on the bottom
            //DLog("AVCaptureVideoOrientationPortrait")
            captureOrientation = AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            // Device oriented vertically, home button on the top
            //DLog("AVCaptureVideoOrientationPortraitUpsideDown")
            captureOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            // Device oriented horizontally, home button on the right
            //DLog("AVCaptureVideoOrientationLandscapeLeft")
            captureOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            // Device oriented horizontally, home button on the left
            //DLog("AVCaptureVideoOrientationLandscapeRight")
            captureOrientation = AVCaptureVideoOrientation.landscapeRight
        default:
            captureOrientation = defaultOrientation
        }
        return captureOrientation
    }
    
    // MARK: Request permissions
    var cameraAuthorized: Bool = false {
        // Swift has a simple and classy solution called property observers, and it lets you execute code whenever a property has changed. To make them work, you need to declare your data type explicitly (in our case we need an Bool), then use either didSet to execute code when a property has just been set, or willSet to execute code before a property has been set.
        didSet {
            if cameraAuthorized {
                DLog("cameraAuthorized")
                checkMicAuthorizationStatus()
            } else {
                DispatchQueue.main.async {
                    self.presentCameraAccessAlert()
                }
            }
        }
    }
    
    var micAuthorized: Bool = false {
        didSet {
            if micAuthorized {
                DLog("micAuthorized")
                DispatchQueue.main.async {
                    self.startCapture()
                }
            } else {
                DispatchQueue.main.async {
                    self.presentMicAccessAlert()
                }
            }
        }
    }
    
    var deviceAuthorized: Bool {
        get {
            return cameraAuthorized && micAuthorized
        }
    }
    
    func checkForAuthorizationStatus() {
        DLog("checkForAuthorizationStatus")
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            cameraAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                granted in
                if granted {
                    DLog("cam granted: \(granted)")
                    self.cameraAuthorized = true
                    DLog("raw value: \(AVCaptureDevice.authorizationStatus(for: AVMediaType.video).rawValue)")
                } else {
                    self.cameraAuthorized = false
                }
            })
        default:
            cameraAuthorized = false
        }
    }
    
    func checkMicAuthorizationStatus() {
        DLog("checkMicAuthorizationStatus")
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            micAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: {
                granted in
                if granted {
                    DLog("mic granted: \(granted)")
                    self.micAuthorized = true
                    DLog("raw value: \(AVCaptureDevice.authorizationStatus(for: AVMediaType.audio).rawValue)")
                } else {
                    self.micAuthorized = false
                }
            })
        default:
            micAuthorized = false
        }
    }
    
    func openSettings() {
        
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url)
        }
    }
    
    func setupPreviews() {
        if let session = streamer?.session {
            pipLayer = AVCaptureVideoPreviewLayer(session: session)
            pipLayer?.frame = pipLayerImage.frame
            pipLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            pipResizeView.delegate = self
            videoRecordView.addSubview(fullLayerImage)
            fullLayerImage.fillSuperview()
            videoRecordView.addSubview(pipResizeView)
            
            updateOrientation()
        }
    }
    
    func adjustPipPreviewPosition() {
        guard streamer != nil,
              let fullLayer = self.fullLayer else {
            return
        }
        
        let pipResizeView = self.pipResizeView
        let pipLayer = self.pipLayerImage
        let viewWidth = videoRecordView.frame.width
        let viewHeight = videoRecordView.frame.height
        if let resizeFrame = self.resizableFrame {
            pipResizeView.frame = resizeFrame
            if let dragView = dragZoneView {
                streamer?.updatePipTransform(frame: resizeFrame, parent: dragView.frame)
            }
        } else {
            let vHeight: CGFloat = viewHeight / 3
            let vWidth = vHeight * 0.61
            pipResizeView.frame = CGRect(x: dragZoneView!.frame.width - vWidth, y: (viewHeight - vHeight), width: vWidth, height: vHeight)
            streamer?.updatePipTransform(frame: pipResizeView.frame, parent: dragZoneView!.frame)
        }
        pipLayer.frame = pipResizeView.frame
        fullLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        pipResizeView.setResizedFrame(newFrame: pipLayer.frame)
        pipResizeView.keepAspectEnabled = true
    }
    
    func updatePreviewOrientation() {
        // previewLayerImage?.orientation = (streamer?.position == .front) ? .downMirrored : .up
    }
    
    func displayUI() {
        btnSave.isHidden = true
    }
    
    func recordButtonUI(state: Int) {
        if state == 0 {
            recordBtn.setTitle("Start Recording", for: .normal)
            recordBtn.backgroundColor = UIColor(hex: "FFBF09")
            recordBtn.isEnabled = true
            recordBtn.alpha = 1
            recordBtn.tag = state
            btnSave.isHidden = true
        } else if state == 1 {
            recordBtn.isEnabled = false
            recordBtn.alpha = 0.6
            btnSave.isHidden = true
        } else if state == 2 {
            recordBtn.setTitle("Stop Recording", for: .normal)
            recordBtn.backgroundColor = UIColor(hex: "f3736c")
            recordBtn.isEnabled = true
            recordBtn.tag = state
            btnSave.isHidden = true
        } else if state == 3 {
            recordBtn.setTitle("Delete Record", for: .normal)
            recordBtn.backgroundColor = UIColor(hex: "fd663f")
            recordBtn.isEnabled = true
            recordBtn.tag = state
            btnSave.isHidden = false
        }
    }
    
    func adjustPipPosition() {
        if streamer != nil {
            guard let fullLayer = self.fullLayer, let pipLayer = self.pipLayer else {
                return
            }
            let viewWidth = videoRecordView.frame.width
            let viewHeight = videoRecordView.frame.height
            
            fullLayer.removeFromSuperlayer()
            pipLayer.removeFromSuperlayer()
            fullLayer.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
            pipLayer.frame = CGRect(x: viewWidth / 2, y: viewHeight / 2, width: viewWidth / 2, height: viewHeight / 2)
            
            videoRecordView.layer.addSublayer(fullLayer)
            videoRecordView.layer.insertSublayer(pipLayer, above: fullLayer)

            adjustPipPreviewPosition()
        }
    }
    
    //    override var prefersStatusBarHidden: Bool {
    //        return true
    //    }
    
    // MARK: Alert dialogs
    func presentCameraAccessAlert() {
        let title = NSLocalizedString("Camera is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the camera in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentMicAccessAlert() {
        let title = NSLocalizedString("Microphone is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the microphone in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentAccessAlert(title: String, message: String) {
        let settingsButtonTitle = NSLocalizedString("Go to settings", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { [weak self] _ in
            self?.openSettings()
            self?.alertController = nil
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { [weak self] _ in
            self?.alertController = nil
        }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        presentAlertController(alertController)
        
        // Also update error message on screen, because user can occasionally cancel alert dialog
        showStatusMessage(message: "Application doesn't have all permissions to use camera and microphone, please change privacy settings.".localized)
    }

    
    func dismissAlertController() {
        alertController?.dismiss(animated: false)
        alertController = nil
    }
    
    func presentAlertController(_ alertController: UIAlertController) {
        dismissAlertController()
        present(alertController, animated: false)
        self.alertController = alertController
    }
    
    func showStatusMessage(message: String) {
        Toast(text: message).show()
    }
    
    // MARK: Connection status UI
    func timeToString(time: Int) -> String {
        let sec = time
        let min = Int((time / 60) % 60)
        let hrs = Int(time / 3600)
        let str = String.localizedStringWithFormat(NSLocalizedString("%02d:%02d:%02d", comment: ""), hrs, min, sec)
        return str
    }
    
    func trafficToString(bytes: UInt64) -> String {
        if bytes < 1024 {
            // b
            return String.localizedStringWithFormat(NSLocalizedString("%4dB", comment: ""), bytes)
        } else if bytes < 1024 * 1024 {
            // Kb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fKB", comment: ""), Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            // Mb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fMB", comment: ""), Double(bytes) / (1024 * 1024))
        } else {
            // Gb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fGB", comment: ""), Double(bytes) / (1024 * 1024 * 1024))
        }
    }
    
    func bandwidthToString(bps: Double) -> String {
        if bps < 1000 {
            // b
            return String.localizedStringWithFormat(NSLocalizedString("%4dbps", comment: ""), Int(bps))
        } else if bps < 1000 * 1000 {
            // Kb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fKbps", comment: ""), bps / 1000)
        } else if bps < 1000 * 1000 * 1000 {
            // Mb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fMbps", comment: ""), bps / (1000 * 1000))
        } else {
            // Gb
            return String.localizedStringWithFormat(NSLocalizedString("%3.1fGbps", comment: ""), bps / (1000 * 1000 * 1000))
        }
    }
}

// MARK: Application state transition
extension FaceCamVC: ApplicationStateObserver {
    func applicationDidBecomeActive() {
        resumeCapture(shouldRequestPermissions: false)
    }
    
    func resumeCapture(shouldRequestPermissions: Bool) {
        if viewIfLoaded?.window != nil {
            DLog("didBecomeActive")
            // Handle view transition from background
            if deviceAuthorized {
                startCapture()
            } else {
                if shouldRequestPermissions {
                    checkForAuthorizationStatus()
                } else {
                    // permission request already in progress and app is returning from permission request dialog
                    // capture will start on permission granted
                    DLog("skip resumeCapture")
                }
            }
        }
    }
    
    func applicationWillResignActive() {
        dismissAlertController()
        
        if viewIfLoaded?.window != nil {
            DLog("willResignActive")
            
            if deviceAuthorized {
                stopCapture()
                removePreview()
                
                ToastCenter.default.cancelAll()
            }
        }
    }
    
    // MARK: Respond to the media server crashing and restarting
    // https://developer.apple.com/library/archive/qa/qa1749/_index.html
    
    func mediaServicesWereLost() {
        if viewIfLoaded?.window != nil, deviceAuthorized {
            DLog("mediaServicesWereLost")
            
            stopCapture()
            removePreview()
            
            showStatusMessage(message: NSLocalizedString("Waiting for media services initialize.", comment: ""))
        }
    }
    
    func mediaServicesWereReset() {
        if viewIfLoaded?.window != nil, deviceAuthorized {
            DLog("mediaServicesWereReset")
            startCapture()
        }
    }
}

extension FaceCamVC: StreamerFacecamManagerDelegate {
    func showToast(text: String) {
        Toast(text: text).show()
    }
    
    func photoSaved(fileUrl: URL) {
        let dest = Settings.sharedInstance.recordStorage
//        cloudUtils.movePhoto(fileUrl: fileUrl, to: dest)
        if dest == .local {
            DispatchQueue.main.async {
                Toast(text: String.localizedStringWithFormat(NSLocalizedString("%@ saved to app's documents folder.", comment: ""), fileUrl.lastPathComponent), duration: Delay.short).show()
            }
        }
    }
    
    func videoSaved(fileUrl: URL) {
        videoRecordURL = fileUrl
//        let dest = Settings.sharedInstance.recordStorage
//        cloudUtils.moveVideo(fileUrl: fileUrl, to: dest)
    }
    
    func didOutputCGImage(outputImage: CGImage?, pipImage: CGImage?) {
        if videoRangeSlider.isRecording,
           let seconds = streamer?.playerItem?.currentTime().seconds {
            videoRangeSlider.updateProgressIndicator(seconds: seconds)
        }
        if let outputImage = outputImage {
            fullLayerImage.currentCGImage = outputImage
            let isVideoPortal = outputImage.width < outputImage.height
            if isAdjustPipPos != isVideoPortal {
                isAdjustPipPos = isVideoPortal
//                if outputImage.width < outputImage.height {
//                    dragZoneView.frame = CGRect(x: 0, y: 0, width: CGFloat(outputImage.width) * (fullLayerImage.frame.height / CGFloat(outputImage.height)), height: fullLayerImage.frame.height)
//                    dragZoneView.center = fullLayerImage.center
//                } else {
//                    dragZoneView.frame = fullLayerImage.bounds
//                }
                resizableFrame = nil
//                adjustPipPreviewPosition()
            }
        }
        if let pipImage = pipImage {
            pipLayerImage.currentCGImage = pipImage
        }
    }
    
    func recordStateDidChange(state: RecordFacecameState, status: Error?) {
        DispatchQueue.main.async {
            switch state {
                case .setup:
//                    SwiftOverlays.showBlockingWaitOverlayWithText("Start record...")
                    self.recordButtonUI(state: 2)
                    break
                case .setuped:
                    break
                case .started:
//                    SwiftOverlays.removeAllBlockingOverlays()
                    self.videoRangeSlider.isRecording = true
                    self.streamer?.player?.play()
                    break
                case .stop, .stopByCancel:
//                    SwiftOverlays.showBlockingWaitOverlayWithText("Stop record...")
                    if self.videoRangeSlider.isRecording {
                        self.recordButtonUI(state: state == .stop ? 3 : 0)
                    }
                    self.videoRangeSlider.isRecording = false
                    self.streamer?.player?.pause()
                    break
                case .stopped:
//                    SwiftOverlays.removeAllBlockingOverlays()
                    break
                case .failed:
                    self.recordButtonUI(state: 0)
//                    SwiftOverlays.removeAllBlockingOverlays()
                    DLog(status?.localizedDescription ?? "")
                    Toast(text: "Record failed").show()
                    break
                case .none:
                    break
            }
        }
    }
    
    // Method may be called on a background thread. Move UI update code inside the main queue.
    func captureStateDidChange(state: CaptureState, status: Error) {
        DispatchQueue.main.async {
            self.onCaptureStateChange(state: state, status: status)
        }
    }
    
    func onCaptureStateChange(state: CaptureState, status: Error) {
        //DLog("captureStateDidChange: \(state) \(status.localizedDescription)")
        
        switch (state) {
        case .CaptureStateStarted:
            setupPreviews()
            
        case .CaptureStateFailed:
            stopCapture()
            removePreview()
            
            showStatusMessage(message: "An error occured with camera")
            
        case .CaptureStateCanRestart:
            showStatusMessage(message: String.localizedStringWithFormat(NSLocalizedString("You can try to restart capture now.", comment: ""), status.localizedDescription))
            
        case .CaptureStateSetup:
            DLog(status.localizedDescription)
            //showStatusMessage(message: status.localizedDescription)
            
        default: break
        }
    }
}

extension FaceCamVC: OTResizableViewDelegate {
    
    func tapBegin(_ resizableView: OTResizableView) {
        resizableView.resizeEnabled = resizableView.resizeEnabled ? false : true
        
        print("tapBegin:\(resizableView.frame)")
    }
    
    
    func tapChanged(_ resizableView: OTResizableView) {
        print("tapChanged:\(resizableView.frame))")
        pipLayer?.frame = pipLayerImage.frame
    }
    
    
    func tapMoved(_ resizableView: OTResizableView) {
        print("tapMoved:\(resizableView.frame))")
    }
    
    
    func tapEnd(_ resizableView: OTResizableView) {
        print("tapEnd:\(resizableView.frame)")
        if let dragView = dragZoneView {
            streamer?.updatePipTransform(frame: resizableView.frame, parent: dragView.frame)
        }
        resizableFrame = resizableView.frame
    }
}

extension FaceCamVC: VideoRecordSliderDelegate {
    func didChangeValue(videoRangeSlider: VideoRecordSlider, startTime: Float64, endTime: Float64) {
        
    }
    
    func indicatorDidChangePosition(videoRangeSlider: VideoRecordSlider, position: Float64) {
        
    }
    
    func sliderGesturesBegan() {
        recordButtonUI(state: 1)
    }
    
    func sliderGesturesEnded() {
        recordButtonUI(state: recordBtn.tag)
        streamer?.player?.seek(to: CMTime(seconds: videoRangeSlider.currentSecond, preferredTimescale: 1000))
    }
}
