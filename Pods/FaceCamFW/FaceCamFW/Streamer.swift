import AVFoundation
import CoreImage
import UIKit

enum StreamerError: Error {
    case DeviceNotAuthorized
    case NoDelegate
    case NoVideoConfig
    case NoAudioConfig
    case SetupFailed
    case MultiCamNotSupported
}

