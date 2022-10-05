//
//  ScreencasterDelegate.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation


enum CaptureStatus: Error {
    case CaptureStatusSuccess
    case CaptureStatusErrorSetup(String, String)
    case CaptureStatusErrorAudio
    case CaptureStatusErrorVideo
    
    var isFailure: Bool {
        //return self != .CaptureStatusSuccess
        switch self {
        case .CaptureStatusSuccess:
            return false
        default:
            return true
        }
    }
}

extension CaptureStatus: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .CaptureStatusSuccess:
            return NSLocalizedString("No error", comment: "")
        case .CaptureStatusErrorSetup(let name, let url):
            return String.localizedStringWithFormat(NSLocalizedString("Could not create connection \"%@\" (%@).", comment: ""), name, url)
        case .CaptureStatusErrorAudio:
            return NSLocalizedString("Can't start audio encoding", comment: "")
        case .CaptureStatusErrorVideo:
            return NSLocalizedString("Can't start video encoding", comment: "")
        }
    }
}

protocol ScreencasterDelegate: class {
    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!)
}


