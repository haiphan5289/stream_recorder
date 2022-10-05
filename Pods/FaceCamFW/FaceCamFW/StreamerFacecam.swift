//
//  StreamerFacecamManager.swift
//  stream_recorder
//
//  Created by HHumorous on 14/04/2022.
//

import CoreImage
//import CocoaLumberjack
//import Toaster
import AVFoundation

public enum RecordFacecameState {
    case none
    case setup
    case setuped
    case started
    case stop
    case stopByCancel
    case stopped
    case failed
}

public enum RecordError: Error {
    case setupFailed
    case saveFailed
}

public protocol ApplicationStateObserver: AnyObject {
    func applicationDidBecomeActive()
    func applicationWillResignActive()
    
    func mediaServicesWereLost()
    func mediaServicesWereReset()
}

public protocol StreamerFacecamManagerDelegate: AnyObject {
    func showToast(text: String)
    func captureStateDidChange(state: CaptureState, status: Error)
    func recordStateDidChange(state: RecordFacecameState, status: Error?)
    func photoSaved(fileUrl: URL)
    func videoSaved(fileUrl: URL)
    func didOutputCGImage(outputImage: CGImage?, pipImage: CGImage?)
}

@available(iOS 13.0, *)
public class StreamerFacecamManager: NSObject {
    public weak var delegate: StreamerFacecamManagerDelegate?
    
    // AVCaptureSession
    public var session: AVCaptureSession?
    public var videoConfig: VideoConfig?
    public var audioConfig: AudioConfig?
    public var sessionQueue = DispatchQueue(label: "FacecameQueue")
    
    // local video
    public var player: AVPlayer?
    public var playerItem: AVPlayerItem?
    public var videoOutput: AVPlayerItemVideoOutput?
    
    // video
    public var captureDevice: AVCaptureDevice?
    public var videoIn: AVCaptureDeviceInput?
    public var videoOut: AVCaptureVideoDataOutput?
    public var videoConnection: AVCaptureConnection?
    public var transform: ImageTransform?
    public var pipTransform: ImageTransform?

    // jpeg capture
    public var imageOut: AVCaptureOutput?
    
    // audio
    public var recordDevice: AVCaptureDevice?
    public var audioIn: AVCaptureInput?
    public var audioOut: AVCaptureAudioDataOutput?
    public var audioConnection: AVCaptureConnection?

    // mp4 record
    public var fileWriter: AVAssetWriter?
    public var videoInput: AVAssetWriterInput?
    public var audioInput: AVAssetWriterInput?
    public var pixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    public var isRecordSessionStarted = false
    public var recordStatus: RecordFacecameState = .none

    public let PixelFormat_YUV = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange

    // live rotation
    public var orientation: AVCaptureVideoOrientation = .landscapeLeft
    public var ciContext: CIContext?
    public var position: AVCaptureDevice.Position = .back
    public let PixelFormat_RGB = kCVPixelFormatType_32BGRA
    
    public var streamWidth: Int = 192
    public var streamHeight: Int = 144
    
    public init(postprocess: Bool) {
        self.postprocess = postprocess
    }

    var postprocess: Bool
    
    var videoOrientation: AVCaptureVideoOrientation {
        // CoreImage filters enabled, we will rotate video on app side, so request not rotated buffers
        if postprocess {
            return .landscapeRight
        } else {
            // CoreImage filters disabled; camera will rotate buffers for us
            if videoConfig!.portrait {
                return .portrait
            } else {
                return .landscapeRight
            }
        }
    }
    
    var isWriting: Bool {
        return recordStatus == .started && isRecordSessionStarted
    }
    
    func setVideoStabilizationMode(mode: AVCaptureVideoStabilizationMode, connection: AVCaptureConnection, camera: AVCaptureDevice) {
        let cameraName = camera.localizedName
//        if dynamicLogLevel == .verbose {
//            let dict:[AVCaptureVideoStabilizationMode:String] = [
//                .off: "off",
//                .standard: "standard",
//                .cinematic: "cinematic",
//                .auto: "auto",
//            ]
//            ////DLog("\(cameraName) supports stabilization: \(connection.isVideoStabilizationSupported)")
//            let modes: [AVCaptureVideoStabilizationMode] = [.off, .standard, .cinematic, .auto]
//            for (_, value) in modes.enumerated() {
//                ////DLog("\(String(describing: dict[value])) \(camera.activeFormat.isVideoStabilizationModeSupported(value))")
//            }
//        }
        
//        let mode = Settings.sharedInstance.videoStabilizationMode
        if connection.isVideoStabilizationSupported, camera.activeFormat.isVideoStabilizationModeSupported(mode) {
            connection.preferredVideoStabilizationMode = mode
//            ////DLog("\(cameraName) preferred stabilization mode: \(connection.preferredVideoStabilizationMode.rawValue)")
//            ////DLog("\(cameraName) active stabilization mode: \(connection.activeVideoStabilizationMode.rawValue)")
        }
    }
    
    func setupAudio() throws {
        // start audio input configuration
        recordDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        guard recordDevice != nil else {
//            ////DLog("streamer fail: can't open audio device")
            throw StreamerError.SetupFailed
        }
        
        do {
            audioIn = try AVCaptureDeviceInput(device: recordDevice!)
        } catch {
//            ////DLog("streamer fail: can't allocate audio input: \(error)")
            throw StreamerError.SetupFailed
        }
        
        if session!.canAddInput(audioIn!) {
            session!.addInput(audioIn!)
        } else {
//            ////DLog("streamer fail: can't add audio input")
            throw StreamerError.SetupFailed
        }
        // audio input configuration completed
        
        // start audio output configuration
        audioOut = AVCaptureAudioDataOutput()
        audioOut!.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session!.canAddOutput(audioOut!) {
            session!.addOutput(audioOut!)
        } else {
//            ////DLog("streamer fail: can't add audio output")
            throw StreamerError.SetupFailed
        }
        
        self.audioConnection = audioOut!.connection(with: AVMediaType.audio)
        guard self.audioConnection != nil else {
//            ////DLog("streamer fail: can't allocate audio connection")
            throw StreamerError.SetupFailed
        }
        // audio output configuration completed
    }
    
    func setCameraParams(camera: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var activeFormat: AVCaptureDevice.Format?
        var formats: [AVCaptureDevice.Format] = []
        
        for format in camera.formats {
            if !isValidFormat(format)  {
                continue
            }
            //D////DLogInfo("format: \(format.debugDescription)")
            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if resolution.width == videoConfig!.videoSize.width, resolution.height == videoConfig!.videoSize.height {
                formats.append(format)
                for range in format.videoSupportedFrameRateRanges {
//                    ////DLog("\(camera.localizedName) found \(resolution.width)x\(resolution.height) [\(range.minFrameRate)..\(range.maxFrameRate)]")
                }
            }
        }
//        ////DLog("\(camera.localizedName) has \(formats.count) format(s)")
        
        // Try to fit requested frame rate into supported fps range
        for format in formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate >= videoConfig!.fps, range.minFrameRate <= videoConfig!.fps {
                    activeFormat = format
//                    ////DLog("\(camera.localizedName) set [\(range.minFrameRate)..\(range.maxFrameRate)]")
                    break
                }
            }
            if activeFormat != nil {
                break
            }
        }
        
        // Requested frame rate is not supported by active camera, fallback to 30 fps
        if activeFormat == nil {
            for format in formats {
                activeFormat = format
                // Can use only supported fps, otherwise capture crashes
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate < videoConfig!.fps {
                        self.videoConfig!.fps = range.maxFrameRate
//                        ////DLog("Unsupported fps, reset to: \(videoConfig!.fps)")
                    } else if range.minFrameRate > videoConfig!.fps {
                        self.videoConfig!.fps = range.minFrameRate
//                        ////DLog("Unsupported fps, reset to: \(videoConfig!.fps)")
                    }
                }
                break
            }
        }
        
        guard let format = activeFormat  else {
//            ////DLog("streamer fail: can't find video output format")
            return nil
        }
        
        do {
            try camera.lockForConfiguration()
        } catch {
//            ////DLog("streamer fail: can't lock video device for configuration: \(error)")
           return nil
        }
        
        camera.activeFormat = format
        camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig!.fps))
        camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig!.fps))
        
        camera.unlockForConfiguration()
        
        return format
    }
    
    private func setupAudioSession(preferredInput: AVAudioSession.Port?) throws {
        let audioSession = AVAudioSession.sharedInstance()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession)
        
        if let inputs = audioSession.availableInputs, let preferredInput = preferredInput {
            for input in inputs {
//                ////DLog("\(input)")
                if input.portType == preferredInput {
                    try audioSession.setPreferredInput(input)
                }
            }
        }
//        showMicInfo()
    }
    
    private func showMicInfo() {
        let audioSession = AVAudioSession.sharedInstance()
        for input in audioSession.currentRoute.inputs {
            let message = input.portName
            DispatchQueue.main.async {
                self.delegate?.showToast(text: message)
            }
//            ////DLog("Active input: \(input), h/w sample rate: \(audioSession.sampleRate)")
        }
    }
    
    private func videoSizeConfig() {
        if videoConfig!.portrait {
            streamHeight = Int(videoConfig!.videoSize.width)
            streamWidth = Int(videoConfig!.videoSize.height)
        } else {
            streamWidth = Int(videoConfig!.videoSize.width)
            streamHeight = Int(videoConfig!.videoSize.height)
        }
    }

    func setupVideoIn() throws {
        // start video input configuration
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        if captureDevice == nil {
            // wrong cameraID? ok, pick default one
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }
        
        guard captureDevice != nil else {
//            ////DLog("streamer fail: can't open camera device")
            throw StreamerError.SetupFailed
        }
        
        position = captureDevice!.position
        
        do {
            videoIn = try AVCaptureDeviceInput(device: captureDevice!)
        } catch {
//            ////DLog("streamer fail: can't allocate video input: \(error)")
            throw StreamerError.SetupFailed
        }
        
        if session!.canAddInput(videoIn!) {
            session!.addInput(videoIn!)
        } else {
//            ////DLog("streamer fail: can't add video input")
            throw StreamerError.SetupFailed
        }
        // video input configuration completed
    }
    
    func setupVideoOut(mode: AVCaptureVideoStabilizationMode) throws {
        guard let _ = setCameraParams(camera: captureDevice!) else {
            throw StreamerError.SetupFailed
        }

        let videoOut = AVCaptureVideoDataOutput()
        videoOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: PixelFormat_YUV)]
        videoOut.alwaysDiscardsLateVideoFrames = true
        videoOut.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session!.canAddOutput(videoOut) {
            session!.addOutput(videoOut)
        } else {
            ////DLog("streamer fail: can't add video output")
            throw StreamerError.SetupFailed
        }
        
        guard let videoConnection = videoOut.connection(with: AVMediaType.video) else {
            ////DLog("streamer fail: can't allocate video connection")
            throw StreamerError.SetupFailed
        }
        videoConnection.videoOrientation = self.videoOrientation

        setVideoStabilizationMode(mode: mode, connection: videoConnection, camera: captureDevice!)
        
        self.videoOut = videoOut
        self.videoConnection = videoConnection
        
        if postprocess {
            let videoSize = CMVideoDimensions(width: Int32(streamWidth), height: Int32(streamHeight))
            transform = ImageTransform(size: videoSize)
            transform?.portraitVideo = videoConfig!.portrait
//            transform?.orientation = orientation
            
            if pipTransform == nil {
                pipTransform = ImageTransform(size: videoSize, scale: 0.5)
                pipTransform?.alignX = 1.0
                pipTransform?.alignY = 0.0
                pipTransform?.portraitVideo = videoConfig!.portrait
            }
//            pipTransform?.orientation = orientation
        }
        // video output configuration completed
    }
    
    public func updatePipTransform(frame: CGRect, parent: CGRect) {
        let videoSize = CMVideoDimensions(width: Int32(streamWidth), height: Int32(streamHeight))
        var scale: CGFloat = 0.5
        if frame.width > frame.height {
            scale = frame.width / parent.width
        } else {
            scale = frame.height / parent.height
        }
        pipTransform = ImageTransform(size: videoSize, scale: scale)
        var alignX: CGFloat = frame.midX
        if frame.minX == 0 {
            alignX = frame.minX
        } else if frame.maxX == parent.width {
            alignX = frame.maxX
        }
        var alignY: CGFloat = frame.midY
        if frame.minY == 0 {
            alignY = frame.minY
        } else if frame.maxY == parent.height {
            alignY = frame.maxY
        }
        pipTransform?.alignX = (alignX * 100 / parent.width) / 100
        pipTransform?.alignY = ((parent.height - alignY) * 100 / parent.height) / 100
        pipTransform?.portraitVideo = videoConfig!.portrait
    }
    
    // MARK: mp4 record
    public func startRecord() {
        self.recordStatus = .setup
        self.delegate?.recordStateDidChange(state: .setup, status: nil)
        sessionQueue.async { [weak self] in
            guard let `self` = self,
                  self.fileWriter == nil else {
                // record is in progress
                return
            }
            ////DLog("start record")
            do {
                let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let df = DateFormatter()
                df.dateFormat = "yyyyMMddHHmmss"
                let fileName = "MVI_" + df.string(from: Date()) + ".mov"
                let fileUrl = documents.appendingPathComponent(fileName)
                
                try self.setupFileWriter(outputURL: fileUrl)
                self.recordStatus = .setuped
                self.delegate?.recordStateDidChange(state: .setuped, status: nil)
            } catch {
                self.recordStatus = .failed
                self.delegate?.recordStateDidChange(state: .failed, status: RecordError.setupFailed)
                ////DLog("can't start record: \(error)")
                return
            }
        }
    }

    func setupFileWriter(outputURL: URL) throws {
        fileWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        
        var width  = videoConfig!.videoSize.width
        var height = videoConfig!.videoSize.height
        
        if videoConfig!.portrait {
            width  = videoConfig!.videoSize.height
            height = videoConfig!.videoSize.width
        }
        
        let videoCompressionProps = [AVVideoAverageBitRateKey:Int(videoConfig!.bitrate)] as [String : Any]
        
        var videoCodec = AVVideoCodecType.h264
        if #available (iOS 11.0, *) {
            if videoConfig!.type == kCMVideoCodecType_HEVC {
                videoCodec = AVVideoCodecType.hevc
            }
        }
        
        let videoOutputSettings = [AVVideoCodecKey:videoCodec,
                                   AVVideoCompressionPropertiesKey:videoCompressionProps,
                                   AVVideoWidthKey:Int(width),
                                   AVVideoHeightKey:Int(height)] as [String : Any]
        
        let audioBitrate = audioConfig!.bitrate > 0 ? audioConfig!.bitrate : 64_000
        let audioOutputSettings = [AVFormatIDKey:Int(kAudioFormatMPEG4AAC),
                                   AVNumberOfChannelsKey:1,
                                   AVSampleRateKey:44_100,
                                   AVEncoderBitRateKey:audioBitrate] as [String : Any]
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        
        guard fileWriter != nil, videoInput != nil, audioInput != nil else {
            throw StreamerError.SetupFailed
        }
        
        videoInput!.expectsMediaDataInRealTime = true
        audioInput!.expectsMediaDataInRealTime = true
        
        if postprocess {
            let sourcePixelBufferAttributesDictionary : [String: AnyObject] = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: PixelFormat_RGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: width),
                kCVPixelBufferHeightKey as String: NSNumber(value: height)
            ]
            
            pixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput!,
                                                                    sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }
        
        guard fileWriter!.canAdd(videoInput!), fileWriter!.canAdd(audioInput!) else {
            throw StreamerError.SetupFailed
        }
        
        fileWriter!.add(videoInput!)
        fileWriter!.add(audioInput!)
    }

    public func stopRecord(restart: Bool = false, cancel: Bool = false) {
        ////DLog("stopRecord")
        if recordStatus == .setup || recordStatus == .setuped || recordStatus == .started {
            delegate?.recordStateDidChange(state: cancel ? .stopByCancel : .stop, status: nil)
        }
        recordStatus = .stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.stopWriting(restart: restart, cancel: cancel)
        }
    }
    
    func stopWriting(restart: Bool, cancel: Bool) {
        ////DLog("stop writing, is status: \(recordStatus) is isRecordSessionStarted: \(isRecordSessionStarted)")
        if recordStatus == .stopped || recordStatus == .failed { return }
        audioOut?.setSampleBufferDelegate(nil, queue: nil)

        if isRecordSessionStarted {
            audioInput?.markAsFinished()
            videoInput?.markAsFinished()
            if restart {
                fileWriter?.finishWriting(completionHandler: releaseFileWriterAndRestart)
            } else if cancel {
                fileWriter?.cancelWriting()
                releaseFileWriter()
            } else {
                fileWriter?.finishWriting(completionHandler: releaseFileWriter)
            }
        } else {
            releaseFileWriter()
        }
    }
    
    func releaseFileWriterAndRestart() {
        releaseFileWriter()
        startRecord()
    }
    
    func releaseFileWriter() {
        ////DLog("releaseFileWriter")
        if (isRecordSessionStarted) {
            if let url = fileWriter?.outputURL {
                delegate?.videoSaved(fileUrl: url)
                recordStatus = .stopped
                delegate?.recordStateDidChange(state: recordStatus, status: nil)
            } else {
                recordStatus = .failed
                delegate?.recordStateDidChange(state: recordStatus, status: RecordError.saveFailed)
            }
        } else {
            recordStatus = .stopped
        }
        isRecordSessionStarted = false
        fileWriter = nil
        pixelBufferInput = nil
        videoInput = nil
        audioInput = nil
    }
    
    // MARK: Capture setup
    public func startCapture(preferredInput: AVAudioSession.Port?, mode: AVCaptureVideoStabilizationMode, startAudio: Bool, startVideo: Bool) throws {
        guard delegate != nil else {
            throw StreamerError.NoDelegate
        }
        if startAudio {
            guard AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == AVAuthorizationStatus.authorized else {
                throw StreamerError.DeviceNotAuthorized
            }
            guard audioConfig != nil else {
                throw StreamerError.SetupFailed
            }
        }
        if startVideo {
            guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized else {
                throw StreamerError.DeviceNotAuthorized
            }
            guard videoConfig != nil else {
                throw StreamerError.SetupFailed
            }
        }
        
        sessionQueue.async {
            do {
                guard self.session == nil else {
                    ////DLog("session is running (guard)")
                    return
                }
                ////DLog("startCapture (async)")
                
//                self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepInitial)
                
                // IMPORTANT NOTE:
                
                // The way applications handle audio is through the use of audio sessions. When your app is launched, behind the scenes it is provided with a singleton instance of an AVAudioSession. Your app use the shared instance of AVAudioSession to configure the behavior of audio in the application.
                
                // https://developer.apple.com/documentation/avfoundation/avaudiosession
                
                // Before configuring AVCaptureSession app MUST configure and activate audio session. Refer to AppDelegate.swift for details.
                
                // ===============


                // AVCaptureSession is completely managed by application, libmbl2 will not change neither CaptureSession's settings nor camera settings.
                self.session = AVCaptureSession()

                // We want to select input port (Built-in mic./Headset mic./AirPods) on our own
                // Also it keeps h/w sample rate as is (48kHz for Built-in mic. and 16kHz for AirPods)
                self.session?.automaticallyConfiguresApplicationAudioSession = false

                // Raw audio and video will be delivered to app in form of CMSampleBuffer. Refer to func captureOutput for details.
                
                if startAudio {
//                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepAudioSession)
                    
                    // Prerequisites: AVAudioSession is active.
                    // Refer to AppDelegate.swift / startAudio() for details.
                    try self.setupAudioSession(preferredInput: preferredInput)
                    
//                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepAudio)
                    try self.setupAudio()
                }
                
                if startVideo {
                    if self.postprocess {
//                        self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepFilters)
                        
                        let options = [CIContextOption.workingColorSpace: NSNull(),
                                       CIContextOption.outputColorSpace: NSNull(),
                                       CIContextOption.useSoftwareRenderer: NSNumber(value: false)]
                        self.ciContext = CIContext(options: options)
                        guard self.ciContext != nil else {
                            self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: CaptureStatus.CaptureStatusErrorH264)
                            return
                        }
                    }
                    
                    self.videoSizeConfig()
                    
//                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepVideoIn)
                    try self.setupVideoIn()
                    
//                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepVideoOut)
                    try self.setupVideoOut(mode: mode)
                    
//                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepStillImage)
                    try self.setupStillImage()
                }
                
//                self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepSessionStart)
                
                // Only setup observers and start the session running if setup succeeded.
                self.registerForNotifications()
                self.session!.startRunning()
                // Wait for AVCaptureSessionDidStartRunning notification.
                
            } catch {
                ////DLog("can't start capture: \(error)")
                self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: error)
            }
        }
    }

    func isValidFormat(_ format: AVCaptureDevice.Format) -> Bool {
        return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
            CMFormatDescriptionGetMediaSubType(format.formatDescription) == PixelFormat_YUV
    }

    func setupStillImage() throws {
        if #available(iOS 11.0,*) {
            imageOut = AVCapturePhotoOutput()
        } else {
            let stillPhotoOut = AVCaptureStillImageOutput()
            stillPhotoOut.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG, AVVideoQualityKey:0.85] as [String : Any]
            self.imageOut = stillPhotoOut
        }
        if session!.canAddOutput(imageOut!) {
            session?.addOutput(imageOut!)
        } else {
            ////DLog("streamer fail: can't add still image output")
            throw StreamerError.SetupFailed
        }
    }
    
    public func stopCapture() {
        ////DLog("stopCapture")
        
        sessionQueue.async {
            self.stopRecord(restart: false, cancel: true)
            self.releaseCapture()
        }
    }
    
    public func releaseCapture() {
        // detach compression sessions and mp4 recorder
        videoOut?.setSampleBufferDelegate(nil, queue: nil)
        
        videoConnection = nil
        videoIn = nil
        videoOut = nil
        imageOut = nil
        captureDevice = nil
        recordDevice = nil
        ciContext = nil
        session = nil
        transform = nil
        pipTransform = nil
        
        player = nil
        playerItem = nil
        videoOutput = nil
    }
    
    func changeStablizationMode(mode: AVCaptureVideoStabilizationMode) {
        setVideoStabilizationMode(mode: mode, connection: self.videoConnection!, camera: captureDevice!)
    }
    
    func changeCamera(mode: AVCaptureVideoStabilizationMode) {
        sessionQueue.async {
            guard self.captureDevice != nil, self.videoIn != nil, self.videoOut != nil else {
                return
            }
            
            let preferredPosition:AVCaptureDevice.Position  = (self.captureDevice!.position == .back) ? .front : .back
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera], mediaType: .video, position: preferredPosition)
            
            if discoverySession.devices.count == 0 {
                ////DLog("Not found camera")
                return
            }
            self.attachVideoDevice(videoDevice: discoverySession.devices.first!, mode: mode)
        }
    }
    
    private func attachVideoDevice(videoDevice: AVCaptureDevice, mode: AVCaptureVideoStabilizationMode) {
        var newFormat: AVCaptureDevice.Format?
        for format in videoDevice.formats {
            
            if CMFormatDescriptionGetMediaType(format.formatDescription) != kCMMediaType_Video {
                continue
            }
            if CMFormatDescriptionGetMediaSubType(format.formatDescription) != self.PixelFormat_YUV {
                continue
            }
            
            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if resolution.width == self.videoConfig!.videoSize.width, resolution.height == self.videoConfig!.videoSize.height {
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= self.videoConfig!.fps, range.minFrameRate <= self.videoConfig!.fps {
                        newFormat = format
                        ////DLog("\(videoDevice.localizedName) set \(resolution.width)x\(resolution.height) [\(range.minFrameRate)..\(range.maxFrameRate)]")
                        break
                    }
                }
                if newFormat != nil {
                    break
                }
            }
        }
        guard newFormat != nil else {
//            self.delegate?.notification(notification: StreamerNotification.ChangeCameraFailed)
            return
        }
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = newFormat!
            
            // https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html
            // If you change the focus mode settings, you can return them to the default configuration as follows:
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                if videoDevice.isFocusPointOfInterestSupported {
                    //////DLog("reset focusPointOfInterest")
                    videoDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }
                //////DLog("reset focusMode")
                videoDevice.focusMode = .continuousAutoFocus
            }
            
            videoDevice.unlockForConfiguration()
            
            self.session?.beginConfiguration()
            self.session?.removeInput(self.videoIn!)
            
            self.captureDevice = videoDevice
            self.position = self.captureDevice!.position
            
            self.videoIn = try AVCaptureDeviceInput(device: self.captureDevice!)
            
            if self.session!.canAddInput(self.videoIn!) {
                self.session?.addInput(self.videoIn!)
            } else {
                throw StreamerError.SetupFailed
            }
            
            guard let videoConnection = self.videoOut!.connection(with: AVMediaType.video) else {
                ////DLog("streamer fail: can't allocate video connection")
                throw StreamerError.SetupFailed
            }
            videoConnection.videoOrientation = self.videoOrientation
            self.videoConnection = videoConnection
            self.setVideoStabilizationMode(mode: mode, connection: self.videoConnection!, camera: self.captureDevice!)
            
            self.session?.commitConfiguration()
            
            // On iOS, the receiver's activeVideoMinFrameDuration resets to its default value if receiver's activeFormat changes; Should first change activeFormat, then set fps
            try self.captureDevice!.lockForConfiguration()
            self.captureDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(self.videoConfig!.fps))
            self.captureDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(self.videoConfig!.fps))
            self.captureDevice!.unlockForConfiguration()
            
        } catch {
            ////DLog("can't change camera: \(error)")
            self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: error)
        }
        
//        self.delegate?.notification(notification: StreamerNotification.ActiveCameraDidChange)
    }

    // MARK: Live rotation
    private func rotateAndEncode(sampleBuffer: CMSampleBuffer) {
        
        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        
        var outputBuffer: CVPixelBuffer? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                   streamWidth, streamHeight,
                                                   PixelFormat_RGB,
                                                   outputOptions as CFDictionary?,
                                                   &outputBuffer)
        
        guard status == kCVReturnSuccess, outputBuffer != nil else {
            ////DLog("error in CVPixelBufferCreate")
            return
        }
        
//        if videoConfig?.portrait == false && (orientation == .portrait || orientation == .portraitUpsideDown) {
//            pipTransform?.alignX = (1.0 + CGFloat(streamHeight)/CGFloat(streamWidth) / 3.0) / 2.0
//        } else if videoConfig?.portrait == true && (orientation == .landscapeLeft || orientation == .landscapeRight) {
//            pipTransform?.alignY = (1.0 - CGFloat(streamWidth)/CGFloat(streamHeight) / 3.0) / 2.0
//        } else {
//            pipTransform?.alignX = 1.0
//            pipTransform?.alignY = 0.0
//        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let sourceBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        var useMirrored = false
        if let device = captureDevice, device.position == .front {
            useMirrored = true
            switch orientation {
                case .portrait:
                    pipTransform?.orientation = .portraitUpsideDown
                case .portraitUpsideDown:
                    pipTransform?.orientation = .portrait
                case .landscapeLeft:
                    pipTransform?.orientation = .landscapeRight
                case .landscapeRight:
                    pipTransform?.orientation = .landscapeLeft
                default:
                    pipTransform?.orientation = orientation
            }
        } else {
            pipTransform?.orientation = orientation
        }
//        transform?.orientation = orientation
       
        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer, options: [CIImageOption.colorSpace: NSNull()])
        
        var outputImage: CIImage = sourceImage
        let bounds = CGRect(x: 0, y: 0, width: streamWidth, height: streamHeight)
        guard let pipMatrix = pipTransform?.getMatrix(extent: bounds, mirrored: useMirrored, flipped: true) else {
            ////DLog("Failed to get transformation")
            return
        }
       
        outputImage = outputImage.transformed(by: pipMatrix)
       
        var captureImage: CIImage?
        if let img = playerCaptureImage() {
            captureImage = img.resizeCI(scaleSize: CGSize(width: streamWidth, height: streamHeight))
        }
        
        if let context = ciContext {
            // merge two ciimage
            if let captureImage = captureImage {
                let x: CGFloat = (CGFloat(streamWidth) - captureImage.extent.width) / 2
                let y: CGFloat = (CGFloat(streamHeight) - captureImage.extent.height) / 2
                let videoImage = captureImage.transformed(by: CGAffineTransform(translationX: x, y: y))
                let compoimg = outputImage.composited(over: videoImage)
                context.render(compoimg, to: outputBuffer!, bounds: compoimg.extent, colorSpace: nil)
            } else {
                context.render(outputImage, to: outputBuffer!, bounds: outputImage.extent, colorSpace: nil)
            }
            
            DispatchQueue.main.async {
                if let captureImage = captureImage {
                    self.delegate?.didOutputCGImage(outputImage: context.createCGImage(captureImage, from: captureImage.extent), pipImage: context.createCGImage(outputImage, from: outputImage.extent))
                } else {
                    self.delegate?.didOutputCGImage(outputImage: nil, pipImage: context.createCGImage(outputImage, from: outputImage.extent))
                }
            }
            
            if isWriting, videoInput?.isReadyForMoreMediaData ?? false {
//                ////DLog("appendSampleBuffer video")
                let success = pixelBufferInput?.append(outputBuffer!, withPresentationTime:sampleTime) ?? false
                if !success {
                    ////DLog("video input not ready for more media data, dropping buffer")
                }
            }
        }
    }
    
    func todayString() -> String {
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        return String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
    }
}

// MARK: Notifications from capture session
@available(iOS 13.0, *)
extension StreamerFacecamManager {
    public func registerForNotifications() {
        let nc = NotificationCenter.default
        
        nc.addObserver(
            self,
            selector: #selector(sessionDidStartRunning(notification:)),
            name: NSNotification.Name.AVCaptureSessionDidStartRunning,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionDidStopRunning(notification:)),
            name: NSNotification.Name.AVCaptureSessionDidStopRunning,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionRuntimeError(notification:)),
            name: NSNotification.Name.AVCaptureSessionRuntimeError,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(notification:)),
            name: NSNotification.Name.AVCaptureSessionWasInterrupted,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(notification:)),
            name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
            object: session)
    }
    
    @objc private func sessionDidStartRunning(notification: Notification) {
        ////DLog("AVCaptureSessionDidStartRunning")
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateStarted, status: CaptureStatus.CaptureStatusSuccess)
    }
    
    @objc private func sessionDidStopRunning(notification: Notification) {
        ////DLog("AVCaptureSessionDidStopRunning")
    }
    
    @objc private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        ////DLog("AVCaptureSessionRuntimeError: \(error)")
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: CaptureStatus.CaptureStatusErrorCaptureSession)
    }
    
    @objc private func sessionWasInterrupted(notification: Notification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            ////DLog("AVCaptureSessionWasInterrupted \(reason)")
            
            if reason == .videoDeviceNotAvailableInBackground {
                return // Session will be stopped by Larix app when it goes to background, ignore notification
            }
            
            var status = CaptureStatus.CaptureStatusErrorSessionWasInterrupted // Unknown error
            if reason == .audioDeviceInUseByAnotherClient {
                status = CaptureStatus.CaptureStatusErrorMicInUse
            } else if reason == .videoDeviceInUseByAnotherClient {
                status = CaptureStatus.CaptureStatusErrorCameraInUse
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                status = CaptureStatus.CaptureStatusErrorCameraUnavailable
            }
            delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: status)
        }
    }
    
    @objc private func sessionInterruptionEnded(notification: Notification) {
        ////DLog("AVCaptureSessionInterruptionEnded")
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateCanRestart, status: CaptureStatus.CaptureStatusSuccess)
    }
    
    @objc private func audioSessionRouteChange(notification: Notification) {
        
        if let value = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber, let routeChangeReason = AVAudioSession.RouteChangeReason(rawValue: UInt(value.intValue)) {
            
            if let routeChangePreviousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                ////DLog("\(#function) routeChangePreviousRoute: \(routeChangePreviousRoute)")
            }
            
            switch routeChangeReason {
                
            case AVAudioSession.RouteChangeReason.unknown: break
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonUnknown")
                
            case AVAudioSession.RouteChangeReason.newDeviceAvailable: break
                // e.g. a headset was added or removed
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonNewDeviceAvailable")
                
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable: break
                // e.g. a headset was added or removed
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonOldDeviceUnavailable")
                
            case AVAudioSession.RouteChangeReason.categoryChange: break
                // called at start - also when other audio wants to play
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonCategoryChange")
                
            case AVAudioSession.RouteChangeReason.override: break
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonOverride")
                
            case AVAudioSession.RouteChangeReason.wakeFromSleep: break
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonWakeFromSleep")
                
            case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory: break
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory")
                
            case AVAudioSession.RouteChangeReason.routeConfigurationChange: break
                ////DLog("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonRouteConfigurationChange")
                
            default:
                break
            }
            
            showMicInfo()
        }
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
// MARK: AVCaptureAudioDataOutputSampleBufferDelegate
@available(iOS 13.0, *)
extension StreamerFacecamManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            ////DLog("sample buffer is not ready, skipping sample")
            return
        }
        
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            checkRecording(sampleBuffer: sampleBuffer)
            processVideoSampleBuffer(sampleBuffer, fromOutput: videoDataOutput)
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            processsAudioSampleBuffer(sampleBuffer, fromOutput: audioDataOutput)
        }
    }
    
    func checkRecording(sampleBuffer: CMSampleBuffer) {
        if recordStatus != .setuped && recordStatus != .started { return }
        if fileWriter?.status == AVAssetWriter.Status.failed {
            releaseFileWriter()
            ////DLog("mp4 writer failed")
        } else if !isRecordSessionStarted {
            ////DLog("record session startWriting")
            let started = fileWriter?.startWriting()
            if started ?? false {
                ////DLog("record session start")
                let firstSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                fileWriter?.startSession(atSourceTime: firstSampleTime)
                isRecordSessionStarted = true
                recordStatus = .started
                delegate?.recordStateDidChange(state: .started, status: nil)
                ////DLog("record session started")
            } else {
                releaseFileWriter()
                ////DLog("can't start writing")
            }
        }
    }
    
    func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        if videoDataOutput != videoOut {
            return
        }
        //////DLog("didOutput sampleBuffer: video \(DispatchTime.now())")
        
        // apply CoreImage filters to video; if postprocessing is not required, then just pass buffer directly to encoder and mp4 writer
        if postprocess {
            // rotateAndEncode will also send frame to mp4 writer
            rotateAndEncode(sampleBuffer: sampleBuffer)
        } else {
            if isWriting, videoInput?.isReadyForMoreMediaData ?? false {
                //////DLog("appendSampleBuffer video \(DispatchTime.now())")
                let success = videoInput?.append(sampleBuffer) ?? false
                if !success {
                    ////DLog("video input not ready for more media data, dropping buffer")
                }
            }
        }
    }
    
    func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput audioDataOutput: AVCaptureAudioDataOutput) {
        if isWriting, audioInput?.isReadyForMoreMediaData ?? false {
//            ////DLog("appendSampleBuffer audio \(DispatchTime.now())")
            let success = audioInput?.append(sampleBuffer) ?? false
            if !success {
                ////DLog("audio input not ready for more media data, dropping buffer")
            }
        }
    }
}

@available(iOS 13.0, *)
extension StreamerFacecamManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil, let imageData = photo.fileDataRepresentation() {
            do {
                let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let df = DateFormatter()
                df.dateFormat = "yyyyMMddHHmmss"
                let fileName = "PHOTO_" + df.string(from: Date()) + ".jpg"
                let fileUrl = documents.appendingPathComponent(fileName)
                
                try imageData.write(to: fileUrl, options: .atomic)
                self.delegate?.photoSaved(fileUrl: fileUrl)
                ////DLog("save photo to \(fileUrl.absoluteString)")
            } catch {
                ////DLog("failed to photo jpeg: \(error)")
            }
        }
    }
}

// MARK: Video player
@available(iOS 13.0, *)
extension StreamerFacecamManager: AVPlayerItemOutputPullDelegate {
    public func initVideo(_ videoURL: URL?) {
        guard let url = videoURL else {
            ////DLog( "video not found")
            return
        }
        let assest = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let playerItem = AVPlayerItem(asset: assest)
        let player = AVPlayer(playerItem: playerItem)
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
//        videoOutput.setDelegate(self, queue: sessionQueue)
        player.volume = 20
        player.currentItem?.add(videoOutput)
        self.playerItem = playerItem
        self.player = player
        self.videoOutput = videoOutput
    }
    
    func playerCaptureImage() -> CIImage? {
        var image: CIImage? = nil
        if let currentTime = player?.currentItem?.currentTime(),
           let asset = player?.currentItem?.asset {
            let imageGenerator = AVAssetImageGenerator(asset: asset)

            var timePicture = CMTime.zero
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceAfter = CMTime.zero
            imageGenerator.requestedTimeToleranceBefore = CMTime.zero
            do {
                let ref = try imageGenerator.copyCGImage(at: currentTime, actualTime: &timePicture)
                image = CIImage(cgImage: ref)
            } catch {
                ////DLog("Video Capture: \(error)")
            }
        }
        return image
    }
}
