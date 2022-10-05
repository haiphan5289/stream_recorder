public enum CaptureState {
    case CaptureStateSetup
    case CaptureStateStarted
    case CaptureStateStopped
    case CaptureStateFailed
    case CaptureStateCanRestart
}

public enum CaptureStatus: Error {
    case CaptureStatusSuccess
    case CaptureStatusErrorAac
    case CaptureStatusErrorH264
    case CaptureStatusErrorCaptureSession
    case CaptureStatusErrorCoreImage
    case CaptureStatusErrorMicInUse
    case CaptureStatusErrorCameraInUse
    case CaptureStatusErrorCameraUnavailable
    case CaptureStatusErrorSessionWasInterrupted
    case CaptureStatusErrorMediaServicesWereReset
    case CaptureStatusErrorAudioSessionWasInterrupted
    case CaptureStatusStepInitial
    case CaptureStatusStepAudioSession
    case CaptureStatusStepFilters
    case CaptureStatusStepH264
    case CaptureStatusStepVideoIn
    case CaptureStatusStepVideoOut
    case CaptureStatusStepAudio
    case CaptureStatusStepStillImage
    case CaptureStatusStepSessionStart
}

extension CaptureStatus: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .CaptureStatusSuccess:
            return NSLocalizedString("No error", comment: "")
        case .CaptureStatusErrorAac:
            return NSLocalizedString("Can't start audio encoding", comment: "")
        case .CaptureStatusErrorH264:
            return NSLocalizedString("Can't start video encoding", comment: "")
        case .CaptureStatusErrorCaptureSession:
            return NSLocalizedString("Capture runtime error. Try to restart", comment: "")
        case .CaptureStatusErrorCoreImage:
            return NSLocalizedString("Video frame processing failed", comment: "")
        case .CaptureStatusErrorCameraInUse:
            return NSLocalizedString("Camera in use by another application. Try to restart", comment: "")
        case .CaptureStatusErrorMicInUse:
            return NSLocalizedString("Microphone in use by another application. Try to restart", comment: "")
        case .CaptureStatusErrorCameraUnavailable:
            return NSLocalizedString("Camera unavailable", comment: "")
        case .CaptureStatusErrorSessionWasInterrupted:
            return NSLocalizedString("Capture session was interrupted. Try to restart", comment: "")
        case .CaptureStatusErrorMediaServicesWereReset:
            return NSLocalizedString("Media services were reset. Try to restart", comment: "")
        case .CaptureStatusErrorAudioSessionWasInterrupted:
            return NSLocalizedString("Audio session was interrupted. Try to restart", comment: "")
        case .CaptureStatusStepInitial:
            return NSLocalizedString("Initializing...", comment: "")
        case .CaptureStatusStepAudioSession:
            return NSLocalizedString("Initializing audio session...", comment: "")
        case .CaptureStatusStepFilters:
            return NSLocalizedString("Initializing image filters...", comment: "")
        case .CaptureStatusStepH264:
            return NSLocalizedString("Initializing video encoder...", comment: "")
        case .CaptureStatusStepVideoIn:
            return NSLocalizedString("Initializing video input...", comment: "")
        case .CaptureStatusStepVideoOut:
            return NSLocalizedString("Initializing video output...", comment: "")
        case .CaptureStatusStepAudio:
            return NSLocalizedString("Initializing audio...", comment: "")
        case .CaptureStatusStepStillImage:
            return NSLocalizedString("Initializing still image...", comment: "")
        case .CaptureStatusStepSessionStart:
            return NSLocalizedString("Awaiting capture session start...", comment: "")
        }
    }
}

public enum StreamerNotification {
    case ActiveCameraDidChange
    case ChangeCameraFailed
    case FrameRateNotSupported
}

protocol StreamerAppDelegate: AnyObject {
//    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!)
    func captureStateDidChange(state: CaptureState, status: Error)
    func notification(notification: StreamerNotification)
    func photoSaved(fileUrl: URL)
    func videoRecordStarted()
    func videoSaved(fileUrl: URL)
}
