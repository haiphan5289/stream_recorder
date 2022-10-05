import AVFoundation

#if os(iOS) || os(macOS)
extension AVCaptureSession.Preset {
    static var `default`: AVCaptureSession.Preset = .medium
}
#endif

protocol AVIOUnit {
    var mixer: AVMixer? { get set }
}

protocol AVMixerDelegate: AnyObject {
    func mixer(_ mixer: AVMixer, didOutput audio: AVAudioPCMBuffer, presentationTimeStamp: CMTime)
    func mixer(_ mixer: AVMixer, didOutput video: CMSampleBuffer)
}

/// An object that mixies audio and video for streaming.
public class AVMixer {
    /// The default fps for an AVMixer, value is 30.
    public static let defaultFPS: Float64 = 30
    /// The default videoSettings for an AVMixer.
    public static let defaultVideoSettings: [NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_32BGRA)
    ]

    #if os(iOS) || os(macOS)
    /// The AVCaptureSession options.
    public enum Option: String, KeyPathRepresentable, CaseIterable {
        /// Specifies the fps.
        case fps
        /// Specifie the sessionPreset.
        case sessionPreset
        /// Specifies the video is mirrored.
        case isVideoMirrored
        /// Specifies the audofocus mode continuous.
        case continuousAutofocus
        /// Specifies the exposure mode  continuous.
        case continuousExposure

        #if os(iOS)
        /// Specifies the video stabilization mode
        /// -seealso: https://github.com/shogo4405/HaishinKit.swift/discussions/1012
        case preferredVideoStabilizationMode
        #endif

        public var keyPath: AnyKeyPath {
            switch self {
            case .fps:
                return \AVMixer.fps
            case .sessionPreset:
                return \AVMixer.sessionPreset
            case .continuousAutofocus:
                return \AVMixer.continuousAutofocus
            case .continuousExposure:
                return \AVMixer.continuousExposure
            case .isVideoMirrored:
                return \AVMixer.isVideoMirrored
            #if os(iOS)
            case .preferredVideoStabilizationMode:
                return \AVMixer.preferredVideoStabilizationMode
            #endif
            }
        }
    }
    #else
    /// The AVCaptureSession options. This is a stub.
    public struct Option: KeyPathRepresentable {
        public static var allCases: [AVMixer.Option] = []
        public var keyPath: AnyKeyPath
        // swiftlint:disable nesting
        public typealias AllCases = [Option]
    }
    #endif

    enum MediaSync {
        case video
        case passthrough
    }

    #if os(iOS)
    var preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode {
        get {
            videoIO.preferredVideoStabilizationMode
        }
        set {
            videoIO.preferredVideoStabilizationMode = newValue
        }
    }
    #endif

    #if os(iOS) || os(macOS)
    var fps: Float64 {
        get {
            videoIO.fps
        }
        set {
            videoIO.fps = newValue
        }
    }

    var isVideoMirrored: Bool {
        get {
            videoIO.isVideoMirrored
        }
        set {
            videoIO.isVideoMirrored = newValue
        }
    }

    var continuousExposure: Bool {
        get {
            videoIO.continuousExposure
        }
        set {
            videoIO.continuousExposure = newValue
        }
    }

    var continuousAutofocus: Bool {
        get {
            videoIO.continuousAutofocus
        }
        set {
            videoIO.continuousAutofocus = newValue
        }
    }

    var sessionPreset: AVCaptureSession.Preset = .default {
        didSet {
            guard sessionPreset != oldValue else {
                return
            }
            session.beginConfiguration()
            session.sessionPreset = sessionPreset
            session.commitConfiguration()
        }
    }

    private var _session: AVCaptureSession?
    /// The capture session instance.
    public var session: AVCaptureSession {
        get {
            if _session == nil {
                _session = AVCaptureSession()
                _session?.sessionPreset = .default
            }
            return _session!
        }
        set {
            _session = newValue
        }
    }
    #endif
    /// The recorder instance.
    public lazy var recorder = AVRecorder()

    /// Specifies the drawable object.
    public weak var drawable: NetStreamDrawable? {
        get {
            videoIO.drawable
        }
        set {
            videoIO.drawable = newValue
        }
    }

    var mediaSync = MediaSync.passthrough

    var settings: Setting<AVMixer, Option> = [:] {
        didSet {
            settings.observer = self
        }
    }

    weak var delegate: AVMixerDelegate?

    lazy var audioIO: AVAudioIOUnit = {
        var audioIO = AVAudioIOUnit()
        audioIO.mixer = self
        return audioIO
    }()

    lazy var videoIO: AVVideoIOUnit = {
        var videoIO = AVVideoIOUnit()
        videoIO.mixer = self
        return videoIO
    }()

    lazy var mediaLink: MediaLink = {
        var mediaLink = MediaLink()
        mediaLink.delegate = self
        return mediaLink
    }()

    private var audioTimeStamp = CMTime.zero
    private var videoTimeStamp = CMTime.zero

    /// Create a AVMixer instance.
    public init() {
        settings.observer = self
    }

    func useSampleBuffer(sampleBuffer: CMSampleBuffer, mediaType: AVMediaType) -> Bool {
        switch mediaSync {
        case .video:
            if mediaType == .audio {
                return !videoTimeStamp.seconds.isZero && videoTimeStamp.seconds <= sampleBuffer.presentationTimeStamp.seconds
            }
            if videoTimeStamp == CMTime.zero {
                videoTimeStamp = sampleBuffer.presentationTimeStamp
            }
            return true
        default:
            return true
        }
    }

    #if os(iOS) || os(macOS)
    deinit {
        if let session = _session, session.isRunning {
            session.stopRunning()
        }
    }
    #endif
}

extension AVMixer {
    /// Starts encoding for video and audio data.
    public func startEncoding(delegate: Any) {
        #if os(iOS)
        videoIO.screen?.startRunning()
        #endif
        videoIO.encoder.delegate = delegate as? VideoCodecDelegate
        videoIO.encoder.startRunning()
        audioIO.codec.delegate = delegate as? AudioCodecDelegate
        audioIO.codec.startRunning()
    }

    /// Stops encoding.
    public func stopEncoding() {
        #if os(iOS)
        videoIO.screen?.stopRunning()
        #endif
        videoTimeStamp = CMTime.zero
        audioTimeStamp = CMTime.zero
        videoIO.encoder.delegate = nil
        videoIO.encoder.stopRunning()
        audioIO.codec.delegate = nil
        audioIO.codec.stopRunning()
    }
}

extension AVMixer {
    /// Starts encoding for video and audio data.
    public func startDecoding(_ audioEngine: AVAudioEngine?) {
        mediaLink.startRunning()
        audioIO.startDecoding(audioEngine)
        videoIO.startDecoding()
    }

    /// Stop encoding.
    public func stopDecoding() {
        mediaLink.stopRunning()
        audioIO.stopDecoding()
        videoIO.stopDecoding()
    }
}

extension AVMixer: MediaLinkDelegate {
    // MARK: MediaLinkDelegate
    func mediaLink(_ mediaLink: MediaLink, dequeue sampleBuffer: CMSampleBuffer) {
        _ = videoIO.decoder.decodeSampleBuffer(sampleBuffer)
    }

    func mediaLink(_ mediaLink: MediaLink, didBufferingChanged: Bool) {
        logger.info(didBufferingChanged)
    }
}

#if os(iOS) || os(macOS)
extension AVMixer: Running {
    // MARK: Running
    public var isRunning: Atomic<Bool> {
        .init(session.isRunning)
    }

    public func startRunning() {
        guard !isRunning.value else {
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.session.startRunning()
        }
    }

    public func stopRunning() {
        guard isRunning.value else {
            return
        }
        session.stopRunning()
    }
}
#else
extension AVMixer: Running {
    // MARK: Running
    public var isRunning: Atomic<Bool> {
        .init(false)
    }

    public func startRunning() {
    }

    public func stopRunning() {
    }
}
#endif
