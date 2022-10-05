import CoreMedia
enum SK {
    static let camera_location_key  = "pref_camera"
    static let video_resolution_key = "pref_resolution"
    static let camera_type_key  = "pref_device_type"
    static let multi_cam_key = "pref_multi_cam"
    static let video_orientation_key       = "pref_orientation"
    static let video_bitrate_key  = "pref_video_bitrate"
    static let video_framerate_key = "pref_fps"
    static let video_keyframe_key = "pref_keyframe"
    static let video_codec_type_key = "pref_video_codec_type"
    static let avc_profile_key = "pref_avc_profile"
    static let hevc_profile_key = "pref_hevc_profile"
    static let core_image_key = "pref_core_image"
    static let live_rotation_key = "pref_live_rotation"
    static let stabilization_mode_key = "pref_stabilization_mode"
    static let abr_mode_key = "abr_mode"
    static let adaptive_fps_key = "adaptive_fps"
    static let session_port_key = "pref_session_port"
    static let auto_birate_key = "pref_bitrate_match_resolution"

    static let audio_channels_key  = "pref_channel_count"
    static let audio_bitrate_key = "pref_audio_bitrate"
    static let audio_samplerate_key  = "pref_sample_rate"
    static let radio_mode  = "pref_radio_mode"
    static let volume_keys_capture_key = "pref_volume_keys"

    static let record_stream_key = "pref_record_stream"
    static let record_storage_key = "pref_record_storage"
    static let record_duration_key = "pref_record_duration"
    static let snapshot_format_key = "pref_snapshot_format"
    static let photo_album_id = "pref_photo_album_id"
    
    static let view_mode_key = "pref_preview_mode"
    static let view_display_3x3Grid_key = "pref_grid_33"
    static let view_display_vumeter_key = "pref_display_vumeter"
    static let view_display_safe_margin = "pref_display_safe_margins"
    static let view_safe_margin_ratio = "pref_display_safe_margins_ratio"
    static let view_safe_margin_percent = "pref_display_safe_margins_percent"
    static let view_display_horizon_level = "pref_display_horizon"
    static let view_display_battery = "pref_display_battery"

    static let reset_settings_key = "pref_reset_settings"
    
    static let default_safe_margn_ratio = "4:3,16:9"
    static let default_safe_margin_percent: Float = 5.0

}

class SettingsKeys {

    internal let camera_location_back = "back"
    
    internal let video_resolution_hd = 720

    internal let camera_type_default = "Auto"
    
    internal let VideoResolutions: [Int:CMVideoDimensions] = [
        144: CMVideoDimensions(width: 192, height: 144),
        288: CMVideoDimensions(width: 352, height: 288),
        360: CMVideoDimensions(width: 480, height: 360),
        480: CMVideoDimensions(width: 640, height: 480),
        540: CMVideoDimensions(width: 960, height: 540),
        720: CMVideoDimensions(width: 1280, height: 720),
        1080: CMVideoDimensions(width: 1920, height: 1080),
        2160: CMVideoDimensions(width: 3840, height: 2160)
    ]
    
    internal let video_orientation_landscape = "landscape"
    internal let video_orientation_portrait  = "portrait"
    
    internal let video_bitrate_auto = 0
    
    internal let video_framerate_def = 30.0
    
    internal let video_keyframe_def = 2 // 2 sec.
    
    internal let video_codec_type_h264 = "h264"
    internal let video_codec_type_hevc = "hevc"
    
    internal let baseline = "baseline"
    internal let main = "main"
    internal let high = "high"
    internal let main10 = "main10"
   
    internal let audio_channels_mono = 1 // Mono
    
    internal let audio_bitrate_auto = 0
    
    internal let audio_samplerate_auto = 0.0
    
    internal let radio_mode  = "pref_radio_mode"
    
    internal let live_rotation_on  = "on"
    
    internal let session_port_auto = "AudioSessionPortAutoSelect"
    internal let session_port_mic = "AudioSessionPortBuiltInMic"
    internal let session_port_headset = "AudioSessionPortHeadsetMic"
    internal let session_port_bt = "AudioSessionPortBluetoothHFP"
    
    internal let stabilization_mode_off = "off"
    internal let stabilization_mode_standard = "standard"
    internal let stabilization_mode_cinematic = "cinematic"
    internal let stabilization_mode_cinematic_extended = "cinematicExtended"
    internal let stabilization_mode_auto = "auto"
    
    internal let abr_mode_off = 0
}
