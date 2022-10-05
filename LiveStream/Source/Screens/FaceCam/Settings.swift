import AVFoundation
import AudioUnit
import VideoToolbox
import CocoaLumberjack
import DeviceGuru
import SwiftMessages
import FaceCamFW

// DeviceGuru is a simple lib (Swift) to know the exact type of the device, e.g. iPhone 6 or iPhone 6s.
// https://github.com/InderKumarRathore/DeviceGuru

class Settings: SettingsKeys {
    
    static let sharedInstance = Settings() // Singleton pattern in Swift
    private override init() {
        // This prevents others from using the default '()' initializer for this class.
        
        if #available(iOS 13.0, *) {
            CONFIG_BACK_LENS = [
                AVCaptureDevice.DeviceType.builtInWideAngleCamera.rawValue: "wide",
                AVCaptureDevice.DeviceType.builtInUltraWideCamera.rawValue: "ultrawide",
                AVCaptureDevice.DeviceType.builtInTelephotoCamera.rawValue: "tele"
           ]
        } else {
            CONFIG_BACK_LENS = [:]
        }

    }
    
    private let hardware = DeviceGuru().hardware()
    
    private var isHEVCSupported = false
    
    public enum RecordStorage: String {
        case local = "local"
        case photoLibrary = "photoLibrary"
        case iCloud = "iCloud"
    }
    
    public enum SnapshotFormat: String {
        case jpg = "jpg"
        case heic = "heic"
    }
    
    public enum MultiCamMode: String {
        case off = "off"
        case pip = "pip"
        case sideBySide = "sideBySide"
        case auto = "auto"
    }
   
    private let default_snapshot_format = "jpg"
    private let default_volume_keys = "off"
    private let volume_keys_enabled = "on"

    private let CONFIG_BACK_LENS: [String: String]
    
    private let viewModeMap: [String: AVLayerVideoGravity] = ["fill" : .resizeAspectFill, "fit": .resizeAspect]
    private let viewModeDefault = "fill"
    
    var backCameraZoom: CGFloat = 0
    
    /* https://help.twitch.tv/customer/portal/articles/1262922-open-broadcaster-software
     ​Recommended bitrate for 1080p 3000-3500
     Recommended bitrate for 720p  1800-2500
     Recommended bitrate for 480p  900-1200
     Recommended bitrate for 360p  600-800
     Recommended bitrate for 240p  Up to 500 */
    
    private let VideoBitrates: [String:Int] = ["2160":4500, "1080":3000, "720":2000, "540":1500, "480":1000, "360":700, "288":500, "144":300]
    
    var videoBitrate: Int {
        var bitrate = UserDefaults.standard.integer(forKey: SK.video_bitrate_key)
        if bitrate == video_bitrate_auto {
            bitrate = recommendedBitrate
        }
        return bitrate * 1000 // kbps -> bps
    }
    
    var recommendedBitrate: Int {
        var bitrate = 3000
        let height = UserDefaults.standard.string(forKey: SK.video_resolution_key)
        guard let recommended = VideoBitrates[height ?? String(video_resolution_hd)] else {
            return bitrate
        }
        bitrate = recommended
        // HEVC promises a 50% storage reduction as its algorithm uses efficient coding by encoding video at the lowest possible bit rate while maintaining a high image quality level.
        if videoCodecType == kCMVideoCodecType_HEVC {
            bitrate /= 2
        }
        if fps > 49.0 {
            // Set bitrate to 1.6x for 50+ FPS modes
            bitrate = bitrate * 16 / 10
        }
        return bitrate
    }
    
    private var fps: Double {
        var framerate = UserDefaults.standard.double(forKey: SK.video_framerate_key)
        if framerate == 0 {
            framerate = video_framerate_def
        }
        
        switch hardware {
        case .iphone_4, .ipad_2, .ipad_2_wifi, .ipad_2_cdma:
            if postprocess, resolution.height > 540 {
                framerate = 15
                DDLogVerbose("reduce iphone_4S fps \(resolution) \(framerate)")
            }
        default:
            break
        }
        
        return framerate
    }
    
    private var keyFrameIntervalDuration: Double {
        var interval = UserDefaults.standard.integer(forKey: SK.video_keyframe_key)
        if interval == 0 {
            interval = video_keyframe_def
        }
        return Double(interval)
    }
    
    var cameraPosition: AVCaptureDevice.Position {
        let location = UserDefaults.standard.string(forKey: SK.camera_location_key) ?? camera_location_back
        return location == camera_location_back ? .back : .front
    }
    
    private var cameraID: String {
        let position = cameraPosition
        var defaultCamera: AVCaptureDevice?
        if #available(iOS 10.0, *) {
            if position == .back {
                defaultCamera = getDefaultBackCamera()
            }
            if defaultCamera == nil {
                defaultCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            }
        } else {
            let cameras: [AVCaptureDevice] = AVCaptureDevice.devices(for: .video)
            for camera in cameras {
                if camera.position == position {
                    return camera.uniqueID
                }
            }
            defaultCamera = AVCaptureDevice.default(for: .video)
        }
            
        return defaultCamera?.uniqueID ?? "com.apple.avfoundation.avcapturedevice.built-in_video:0"
    }
    
    private func videoSize(cameraID: String) -> CMVideoDimensions {
        let wantResolution = resolution
        var maxResolution = CMVideoDimensions(width: 192, height: 144)
        
        if let camera = AVCaptureDevice(uniqueID: cameraID) {
            for format in camera.formats {
                
                let mediaType = CMFormatDescriptionGetMediaType(format.formatDescription)
                if mediaType != kCMMediaType_Video {
                    continue
                }
                
                let fourCharCode = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                if fourCharCode != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
                    continue
                }
                
                if #available(iOS 13.0, *)  {
                    if multiCamMode != .off && !format.isMultiCamSupported {
                        continue
                    }
                }
                
                let camResolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                DDLogVerbose("\(camResolution.width)x\(camResolution.height)")
                
                if camResolution.height == wantResolution.height, camResolution.width == wantResolution.width {
                    return camResolution
                }
                // if resolution is not supported (ex: iPhone 4s front camera can't produce 1080p), save max possible resolution
                if camResolution.height >= maxResolution.height, camResolution.height <= 1080 {
                    maxResolution = camResolution
                }
            }
        }
        return maxResolution
    }
    
    var portrait: Bool {
        let orientation = UserDefaults.standard.string(forKey: SK.video_orientation_key)
        return (orientation ?? video_orientation_landscape) == video_orientation_portrait
    }
    
    // To put it simply, no iPhone with a headphone jack will be able to record HEVC videos or take HEIF photos. The chips that support HEVC encoding are the A10 and new A11. The iPhone 7 was the first to have an A10 chip in it.
    
    private var videoCodecType: CMVideoCodecType {
        if #available (iOS 11.0, *) {
            let typeStr = UserDefaults.standard.string(forKey: SK.video_codec_type_key) ?? video_codec_type_h264
            if typeStr == video_codec_type_hevc, isHEVCSupported {
                return kCMVideoCodecType_HEVC
            }
        }
        return kCMVideoCodecType_H264
    }
    
    private var profileLevel: CFString {
        if #available (iOS 11.0, *) {
            if videoCodecType == kCMVideoCodecType_HEVC {
                let hevc = UserDefaults.standard.string(forKey: SK.hevc_profile_key) ?? main
                switch hevc {
                case main10:
                    return kVTProfileLevel_HEVC_Main10_AutoLevel
                default:
                    return kVTProfileLevel_HEVC_Main_AutoLevel
                }
            }
        }
        let avc = UserDefaults.standard.string(forKey: SK.avc_profile_key) ?? baseline
        switch avc {
        case high:
            return kVTProfileLevel_H264_High_AutoLevel
        case main:
            return kVTProfileLevel_H264_Main_AutoLevel
        default:
            return kVTProfileLevel_H264_Baseline_AutoLevel
        }
    }
    
    var videoConfig: VideoConfig {
        let id = cameraID
        let size = videoSize(cameraID: id)
        if #available (iOS 11.0, *) {
            isHEVCSupported = isHEVCEncodingSupported(size: size)
        }
        let codecType = videoCodecType
        
        let config = VideoConfig(
            cameraID: id,
            videoSize: size,
            fps: fps,
            keyFrameIntervalDuration: keyFrameIntervalDuration,
            bitrate: videoBitrate,
            portrait: portrait,
            type: codecType,
            profileLevel: profileLevel)
        
        let nf = NumberFormatter()
        nf.numberStyle = .none
        
        let codecDisplayName = codecType == kCMVideoCodecType_HEVC ? "HEVC" : "H.264"
        let width = nf.string(from: NSNumber(value: size.width)) ?? ""
        let height = nf.string(from: NSNumber(value: size.height)) ?? ""
        
        let profile = profileLevel as String
        let profileArr = profile.components(separatedBy: "_")
        let profileDisplayName = profileArr.count > 2 ? profileArr[1] : ""
        
        let message = String.localizedStringWithFormat(NSLocalizedString("%@ (%@), %@x%@", comment: ""), codecDisplayName, profileDisplayName, width, height)
        
        return config
    }
    
    private var channelCount: Int {
        var channels = UserDefaults.standard.integer(forKey: SK.audio_channels_key)
        if channels == 0 {
            channels = audio_channels_mono
        }
        return channels
    }
    
    private var sampleRate: Double {
        var samplerate = UserDefaults.standard.double(forKey: SK.audio_samplerate_key)
        if samplerate == audio_samplerate_auto {
            samplerate = 0 // Use AVCaptureSession's sample rate and avoid conversion
        }
        return samplerate
    }
    
    var audioConfig: AudioConfig {
        let config = AudioConfig(
            sampleRate: sampleRate,
            channelCount: channelCount,
            bitrate: audioBitrate)
        return config
    }
    
    var radioMode: Bool {
        return UserDefaults.standard.bool(forKey: radio_mode)
    }
    
    var record: Bool {
        return UserDefaults.standard.bool(forKey: SK.record_stream_key)
    }
    
    var postprocess: Bool {
        return true

    }
    
    var canPostprocess: Bool {
        if resolution.height <= 1080 { return true }
        let hw = DeviceGuru().hardwareString()
        let regex = try! NSRegularExpression(pattern: "(\\p{L}+)(\\p{Nd}+)\\,(\\p{N}+)")
        let matches = regex.matches(in: hw, options: [], range: NSRange(location: 0, length: hw.utf16.count))
        if let match = matches.first {
            let typeRange = Range(match.range(at: 1), in: hw)
            let type = String(hw[typeRange!])
            let verRange =  Range(match.range(at: 2), in: hw)
            let ver = Int(hw[verRange!]) ?? 0
            if type == "iPhone" {
                return ver >= 12 //iPhone 11 and newer (iPhone12,x for iPhone 11[Pro][Max] and 12,8 for SE (2 Gen)
            } else if type == "iPad" {
                return ver >= 8 //Using A12X CPU and better
            }
        }
        return false
    }
    
    var liveRotation: Bool {
        let rotation = UserDefaults.standard.string(forKey: SK.live_rotation_key) ?? live_rotation_on
        return rotation == live_rotation_on
    }
    
    private var resolution: CMVideoDimensions {
        var res = UserDefaults.standard.integer(forKey: SK.video_resolution_key)
        if res == 0 {
            res = video_resolution_hd
        }
        return VideoResolutions[res] ?? CMVideoDimensions(width: 1280, height: 720)
    }
    
    var videoStabilizationMode: AVCaptureVideoStabilizationMode {
        if let mode = UserDefaults.standard.string(forKey: SK.stabilization_mode_key) {
            switch mode {
            case stabilization_mode_standard:
                return .standard
            case stabilization_mode_cinematic:
                return .cinematic
            case stabilization_mode_cinematic_extended:
                if #available(iOS 13.0, *) {
                    return .cinematicExtended
                } else {
                    return .cinematic
                }
            case stabilization_mode_auto:
                return .auto
            default:
                return .off
            }
        }
        return .off
    }
    
    var preferredInput: AVAudioSession.Port? {
        if let port = UserDefaults.standard.string(forKey: SK.session_port_key) {
            switch port {
            case session_port_mic:
                return AVAudioSession.Port.builtInMic
            case session_port_headset:
                return AVAudioSession.Port.headsetMic
            case session_port_bt:
                return AVAudioSession.Port.bluetoothHFP
            default:
                return nil
            }
        }
        return nil
    }
    
    private var audioBitrate: Int {
        let bitrate = UserDefaults.standard.integer(forKey: SK.audio_bitrate_key)
        if bitrate == audio_bitrate_auto {
            return 0 // don't set kAudioConverterEncodeBitRate
        }
        return bitrate * 1000 // kbps -> bps
    }
    
    var abrMode: Int {
        return UserDefaults.standard.integer(forKey: SK.abr_mode_key)
    }
    
    var adaptiveFps: Bool {
        return UserDefaults.standard.bool(forKey: SK.adaptive_fps_key)
    }
    
    @available (iOS 11.0, *)
    private func isHEVCEncodingSupported(size: CMVideoDimensions) -> Bool {
        let encoderSpecDict : [String : Any] =
            [kVTCompressionPropertyKey_ProfileLevel as String : kVTProfileLevel_HEVC_Main_AutoLevel,
             kVTCompressionPropertyKey_RealTime as String : true]
        
        let status = VTCopySupportedPropertyDictionaryForEncoder(width: size.width, height: size.height,
                                                                 codecType: kCMVideoCodecType_HEVC,
                                                                 encoderSpecification: encoderSpecDict as CFDictionary,
                                                                 encoderIDOut: nil, supportedPropertiesOut: nil)
        if status == kVTCouldNotFindVideoEncoderErr {
            return false
        }
        if status != noErr {
            return false
        }
        return true
    }
    
    var photoAlbumId: String? {
        get {
            return UserDefaults.standard.string(forKey: SK.photo_album_id)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SK.photo_album_id)
        }
    }
    
    public var recordStorage: RecordStorage {
        let val = UserDefaults.standard.string(forKey: SK.record_storage_key) ?? RecordStorage.local.rawValue
        return RecordStorage.init(rawValue: val) ?? .local
    }
    
    public var recordDuration: Int {
        let duratonMin =  UserDefaults.standard.integer(forKey: SK.record_duration_key)
        return duratonMin * 60
    }
    
    public var snapshotFormat: SnapshotFormat {
        let val = UserDefaults.standard.string(forKey: SK.snapshot_format_key) ?? default_snapshot_format
        return SnapshotFormat.init(rawValue: val) ?? .jpg
    }
    
    public var multiCamMode: MultiCamMode {
        if #available(iOS 13.0, *) {
            if !AVCaptureMultiCamSession.isMultiCamSupported {
                return .off
            }
            let val = UserDefaults.standard.string(forKey: SK.multi_cam_key) ?? MultiCamMode.off.rawValue
            return MultiCamMode(rawValue: val) ?? .off
        } else {
            return .off
        }
    }
    
    @available(iOS 10.0, *)
    func getDefaultBackCamera(probe:((AVCaptureDevice, CMVideoDimensions, Double) -> Bool)? = nil) -> AVCaptureDevice? {
        var defaultType = AVCaptureDevice.DeviceType.builtInDualCamera
        var virtualCamera: AVCaptureDevice?
        let typeStr = UserDefaults.standard.string(forKey: SK.camera_type_key)
        if typeStr != nil && typeStr != camera_type_default {
            defaultType = AVCaptureDevice.DeviceType(rawValue: typeStr!)
            virtualCamera =  AVCaptureDevice.default(defaultType, for: .video, position: .back)
            if virtualCamera != nil {
                return virtualCamera
            }
        }
        if #available(iOS 13.0, *) {
            defaultType = AVCaptureDevice.DeviceType.builtInTripleCamera
            virtualCamera = AVCaptureDevice.default(defaultType, for: .video, position: .back)
            if  virtualCamera == nil || probe?(virtualCamera!, resolution, fps) == false {
                defaultType = AVCaptureDevice.DeviceType.builtInDualWideCamera
            }
        }
        virtualCamera = AVCaptureDevice.default(defaultType, for: .video, position: .back)
        if virtualCamera == nil || probe?(virtualCamera!, resolution, fps) == false {
            defaultType = .builtInWideAngleCamera
            virtualCamera = AVCaptureDevice.default(defaultType, for: .video, position: .back)
        }
        if typeStr != camera_type_default {
            if typeStr != nil {
            }

            UserDefaults.standard.set(camera_type_default, forKey: SK.camera_type_key)
        }
        return virtualCamera
    }
    
    public var volumeKeysCapture: Bool {
        
        let val = UserDefaults.standard.string(forKey: SK.volume_keys_capture_key) ?? default_volume_keys
        return val == volume_keys_enabled
    }
    
    func groveVideoConfig() -> [URLQueryItem] {
        var config: [URLQueryItem] = []
        let id = cameraID
        let camera = cameraPosition == .back ? "0" : "1"
        let size = videoSize(cameraID: id)
        let sizeStr = String(format: "%dx%d", size.width, size.height)
        
        config.append(URLQueryItem(name: "enc[vid][camera]", value: camera))
        config.append(URLQueryItem(name: "enc[vid][res]", value: sizeStr))
        if let orientation = UserDefaults.standard.string(forKey: SK.video_orientation_key) {
            config.append(URLQueryItem(name: "enc[vid][orientation]", value: orientation))
        }
        
        if let typeStr = UserDefaults.standard.string(forKey: SK.camera_type_key) {
            let backCamType = CONFIG_BACK_LENS[typeStr] ?? "auto"
            config.append(URLQueryItem(name: "enc[vid][backLens]", value: backCamType))
        }

        if multiCamMode != .off {
            switch multiCamMode {
            case .off:
                config.append(URLQueryItem(name: "enc[vid][multiCam]", value: "off"))
            case .pip:
                config.append(URLQueryItem(name: "enc[vid][multiCam]", value: "pip"))
            case .sideBySide:
                config.append(URLQueryItem(name: "enc[vid][multiCam]", value: "sbs"))
            default:
                break
            }
        }
        let rotation = UserDefaults.standard.bool(forKey: SK.core_image_key)
        if rotation {
            let live_rotation = UserDefaults.standard.string(forKey: SK.live_rotation_key) ?? ""
            let rotationMode = live_rotation == live_rotation_on ? "follow" : "lock"
            config.append(URLQueryItem(name: "enc[vid][liveRotation]", value: rotationMode))
        } else {
            config.append(URLQueryItem(name: "enc[vid][liveRotation]", value: "off"))
        }
        config.append(URLQueryItem(name: "enc[vid][fps]", value: String(format:"%d",Int(fps))))
        let bitrate = UserDefaults.standard.integer(forKey: SK.video_bitrate_key)
        let bitrateStr = String(format:"%d", bitrate)
        config.append(URLQueryItem(name: "enc[vid][bitrate]", value: bitrateStr))

        let codecName = (videoCodecType == kCMVideoCodecType_HEVC) ? "hevc" : "avc"
        config.append(URLQueryItem(name: "enc[vid][format]", value: codecName))
        config.append(URLQueryItem(name: "enc[vid][keyframe]", value: String(format:"%d",Int(keyFrameIntervalDuration))))
        
        config.append(URLQueryItem(name: "enc[vid][adaptiveBitrate]", value: String(abrMode)))
        let adaptive_fps = adaptiveFps ? "on" : "off"
        config.append(URLQueryItem(name: "enc[vid][adaptiveFps]", value: adaptive_fps))
        return config
    }
    
    func groveAudioConfig() -> [URLQueryItem] {
        var config: [URLQueryItem] = []
        let channels = UserDefaults.standard.string(forKey: SK.audio_channels_key) ?? "1"
        config.append(URLQueryItem(name: "enc[aud][channels]", value: channels))

        let bitrate = UserDefaults.standard.string(forKey: SK.audio_bitrate_key) ?? "0"
        config.append(URLQueryItem(name: "enc[aud][bitrate]", value: bitrate))

        let samplerate = UserDefaults.standard.string(forKey: SK.audio_samplerate_key) ?? "0"
        config.append(URLQueryItem(name: "enc[aud][samples]", value: samplerate))

        let audioOnly = radioMode ? "on" : "off"
        config.append(URLQueryItem(name: "enc[aud][audioOnly]", value: audioOnly))
        
        return config
    }
    
    func groveRecordConfig() -> [URLQueryItem] {
        var config: [URLQueryItem] = []
        let recordOn = record ? "on" : "off"
        config.append(URLQueryItem(name: "enc[record][enabled]", value: recordOn))
        if record {
            let duratonMin = UserDefaults.standard.string(forKey: SK.record_duration_key) ?? "0"
            config.append(URLQueryItem(name: "enc[record][duration]", value: duratonMin))
            var storage: String = ""
            switch recordStorage {
            case .local:
                storage = "local"
            case .iCloud:
                storage = "cloud"
            case .photoLibrary:
                storage = "photo_library"
            }
            config.append(URLQueryItem(name: "enc[record][storage]", value: storage))
        }
        return config
    }
    
    var displayLayerGravity: AVLayerVideoGravity {
        let modeStr = UserDefaults.standard.string(forKey: SK.view_mode_key) ?? viewModeDefault
        return viewModeMap[modeStr] ?? .resizeAspectFill
    }
    
    var displayVuMeter: Bool {
        let display = UserDefaults.standard.string(forKey: SK.view_display_vumeter_key) ?? "1"
        return display == "1"
    }
    
    
    var showOverlayGrid: Bool {
        if radioMode { return false }
        return UserDefaults.standard.bool(forKey: SK.view_display_3x3Grid_key)
    }

    var safeMarginOffset: Float {
        if UserDefaults.standard.value(forKey: SK.view_safe_margin_percent) == nil {
            return SK.default_safe_margin_percent * 0.01
        }
        return UserDefaults.standard.float(forKey: SK.view_safe_margin_percent) * 0.01
    }
    
    var safeMarginRatios: [Float] {
        if radioMode { return [] }
        if UserDefaults.standard.bool(forKey: SK.view_display_safe_margin) == false { return [] }
        let ratiosStr: String = UserDefaults.standard.string(forKey: SK.view_safe_margin_ratio) ?? SK.default_safe_margn_ratio
        let ratioArr = ratiosStr.split(separator: ",")
        let ratiosF = ratioArr.map { (s) -> Float in
            let parts = s.split(separator: ":")
            if parts.count != 2 { return 1.0 }
            let a = Float(parts[0]) ?? 1.0
            let b = Float(parts[1]) ?? 1.0
            return b == 0 ? 1.0 : a / b
        }
        return ratiosF
    }
    
    var showHorizonLevel: Bool {
        if radioMode { return false }
        return UserDefaults.standard.bool(forKey: SK.view_display_horizon_level)
    }
    
    var batteryIndicatorThreshold: Float {
        var val = UserDefaults.standard.float(forKey: SK.view_display_battery)
        if val <= 0 { val = 100 }
        return val
    }

    static let view_display_battery = "pref_display_battery"


    func resetDefaultsIfRequested() {
        let reset = UserDefaults.standard.bool(forKey: SK.reset_settings_key)
        if reset {
            resetDefaults()
            let message = NSLocalizedString("Settings have been reset to default", comment: "")
        }
    }

    func resetDefaults() {
        guard let domain = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    
}
