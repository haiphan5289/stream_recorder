//
//  LiveCameraVC.swift
//  LiveStream
//
//  Created by htv on 15/08/2022.
//

import UIKit
import HaishinKit
import AVFoundation
import Photos
import VideoToolbox

final class RecorderDelegate: DefaultAVRecorderDelegate {
    static let `default` = RecorderDelegate()

    override func didFinishWriting(_ recorder: AVRecorder) {
        guard let writer: AVAssetWriter = recorder.writer else {
            return
        }
        PHPhotoLibrary.shared().performChanges({() -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: writer.outputURL)
        }, completionHandler: { _, error -> Void in
            do {
                try FileManager.default.removeItem(at: writer.outputURL)
            } catch {
                print(error)
            }
        })
    }
}

class LiveCameraVC: BaseVC {
    
    @IBOutlet weak var lfView: MTHKView!
    @IBOutlet weak var liveImageView: UIImageView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var liveButton: UIButton!
    
    private var rtmpConnect = RTMPConnection()
    private var rtmpStream: RTMPStream!
    private var videoEffect: VideoEffect?
    private var posCamera: AVCaptureDevice.Position = .back
    private var retry: Int = 0
    private var indexZoom: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupLive()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio))
        self.rtmpStream.attachCamera(DeviceUtil.device(withPosition: posCamera))
        self.lfView.attachStream(self.rtmpStream)
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.rtmpStream.close()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.liveImageView.isHidden = true
    }
    
    private func setupLive() {
        self.rtmpStream = RTMPStream(connection: self.rtmpConnect)
        rtmpStream.videoSettings = [
            .width: 720,
            .height: 1280,
        ]
        rtmpStream.captureSettings = [
            .sessionPreset: AVCaptureSession.Preset.hd1280x720,
            .continuousExposure: true,
            .continuousAutofocus: true,
        ]
        guard let orientationDevice =
                UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        else { return }
        if let orientation = DeviceUtil.videoOrientation(by: orientationDevice) {
            self.rtmpStream.orientation = orientation
        }
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        self.rtmpStream.captureSettings[.fps] = 25.0
        self.rtmpStream.videoSettings[.bitrate] = 160000
        self.rtmpStream.mixer.recorder.delegate = RecorderDelegate.shared
    }
    
    @IBAction func didTapFlash(_ sender: UIButton) {
        self.rtmpStream.torch.toggle()
    }
    
    @IBAction func didTapFilter(_ sender: UIButton) {
        if let filter = self.videoEffect {
            _ = self.rtmpStream.unregisterVideoEffect(filter)
        }
        
        if sender.isSelected {
            self.videoEffect = MonochromeEffect()
            _ = self.rtmpStream.registerVideoEffect(self.videoEffect!)
        }
        sender.isSelected.toggle()
    }
    
    @IBAction func didTapAntibration(_ sender: UIButton) {
        if sender.isSelected {
            self.rtmpStream.captureSettings[.preferredVideoStabilizationMode] = AVCaptureVideoStabilizationMode.auto
        } else {
            self.rtmpStream.captureSettings[.preferredVideoStabilizationMode] = AVCaptureVideoStabilizationMode.off
        }
        sender.isSelected.toggle()
    }
    
    @IBAction func didTapSwitchCamera(_ sender: UIButton) {
        let pos: AVCaptureDevice.Position = self.posCamera == .back ? .front : .back
        self.rtmpStream.captureSettings[.isVideoMirrored] = pos == .front
        self.rtmpStream.attachCamera(DeviceUtil.device(withPosition: pos))
        self.posCamera = pos
    }
    
    @IBAction func didTapClose(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func didTapZoomIn(_ sender: UIButton) {
        var newIndex = self.indexZoom - 1
        if newIndex < 1 {
            newIndex = 1
        }
        self.indexZoom = newIndex
        self.rtmpStream.setZoomFactor(CGFloat(newIndex), ramping: true, withRate: 5.0)
    }
    
    @IBAction func didTapZoomOut(_ sender: UIButton) {
        var newIndex = self.indexZoom + 1
        if newIndex > 5 {
            newIndex = 5
        }
        self.indexZoom = newIndex
        self.rtmpStream.setZoomFactor(CGFloat(newIndex), ramping: true, withRate: 5.0)
    }
    
    @IBAction func didTapScreenCapture(_ sender: UIButton) {
        rtmpStream.attachScreen(ScreenCaptureSession(shared: UIApplication.shared), useScreenSize: false)
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: posCamera))
        rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
        lfView?.attachStream(rtmpStream)
    }
    
    @IBAction func didTapLive(_ sender: UIButton) {
        if sender.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            self.rtmpConnect.close()
            self.rtmpConnect.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatus), observer: self)
            self.rtmpConnect.removeEventListener(.ioError, selector: #selector(rtmpError), observer: self)
            self.liveButton.setImage(UIImage(named: "ic_live_play"), for: .normal)
            self.liveImageView.isHidden = true
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            self.rtmpConnect.addEventListener(.rtmpStatus, selector: #selector(rtmpStatus), observer: self)
            self.rtmpConnect.addEventListener(.ioError, selector: #selector(rtmpError), observer: self)
            guard let url = Cache.shared.url    ,
                  let key = Cache.shared.key else { return }
            self.rtmpConnect.connect(url + key)
            liveButton.setImage(UIImage(named: "ic_live_stop"), for: .normal)
            self.liveImageView.isHidden = false
        }
        sender.isSelected.toggle()
    }
    
    @IBAction func didTapMicro(_ sender: UIButton) {
        self.rtmpStream.audioSettings[.muted] = sender.isSelected
        sender.isSelected.toggle()
    }
    
    @objc private func rtmpStatus(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            self.retry = 0
            rtmpStream.publish(Cache.shared.key)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard self.retry <= 5 else {
                return
            }
            Thread.sleep(forTimeInterval: pow(2.0, Double(self.retry)))
            guard let url = Cache.shared.url,
                  let key = Cache.shared.key else { return }
            let link = url + key
            self.rtmpConnect.connect(link)
            self.retry += 1
        default:
            break
        }
    }

    @objc
    private func rtmpError(_ notification: Notification) {
        guard let url = Cache.shared.url,
              let key = Cache.shared.url else { return }
        let link = url + key
        self.rtmpConnect.connect(link)
    }
    
    @objc
    private func on(_ notification: Notification) {
        guard let orientationDevice = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            return
        }
        guard let orientation = DeviceUtil.videoOrientation(by: orientationDevice) else {
            return
        }
        self.rtmpStream.orientation = orientation
    }
    
    @objc private func didInterruption(_ notification: Notification) {
    }

    @objc private func didRouteChange(_ notification: Notification) {
    }
    
}
