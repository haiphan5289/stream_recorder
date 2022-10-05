//
//  SampleHandler.swift
//  Broadcast_LiveStream
//
//  Created by htv on 23/08/2022.
//

import ReplayKit
import UserNotifications
import BroadcastWriter

class SampleHandler: RPBroadcastSampleHandler {
    
    private var writer: BroadcastWriter?
    private let fileManager: FileManager = .default
    private let notificationCenter = UNUserNotificationCenter.current()
    private let url: URL
    
    let userDefault = UserDefaults(suiteName: "group.com.recordscreen11")
    var isBroadcast = false
    let streamer: ScreenStreamer
    
    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)
    }
    
    override init() {
        self.streamer = ScreenStreamer.sharedInstance
        if #available(iOSApplicationExtension 14.0, *) {
            self.url = self.fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(for: .mpeg4Movie)
        } else {
            self.url = self.fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
        }

        self.fileManager.removeFileExists(url: self.url)

        super.init()
    }
    
    func setupStream() {
        guard let url = self.userDefault?.string(forKey: "url"),
              let key = self.userDefault?.string(forKey: "key") else { return }
        
        let fullUrl = url + key
        
        let connectionConfig = ConnectionConfig()
        connectionConfig.uri = URL(string: fullUrl)!
        connectionConfig.mode = .videoAudio
        self.isBroadcast = true
        let id = ScreenStreamer.sharedInstance.createConnection(config: connectionConfig)
        
        self.streamer.delegate = self
        let status = self.streamer.startCapture()
        print("status: %@, id: %@, streamUrl: %@", status, id, fullUrl)
    }
    
    func start() {
        do {
            self.writer = try .init(
                outputURL: self.url,
                screenSize: UIScreen.main.bounds.size,
                screenScale: UIScreen.main.scale
            )
        } catch {
            assertionFailure(error.localizedDescription)
            finishBroadcastWithError(error)
            return
        }
        do {
            try self.writer?.start()
            self.userDefault?.set(1, forKey: "broadcast")
            if self.isBroadcast {
                self.userDefault?.set(1, forKey: "stream")
            }
        } catch {
            finishBroadcastWithError(error)
        }
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        self.setupStream()
        self.start()
    }
    
    override func broadcastPaused() {
        if self.isBroadcast {
            self.streamer.pause()
        }
        self.writer?.pause()
    }
    
    override func broadcastResumed() {
        if self.isBroadcast {
            self.streamer.resume()
        }
        self.writer?.resume()
    }
    
    override func broadcastFinished() {
        self.finish()
        if self.isBroadcast {
            self.streamer.stopCapture()
            self.streamer.releaseAllConnections()
        }
    }
    
    func finish() {
        guard let writer = self.writer else {
            return
        }

        let outputURL: URL
        do {
            outputURL = try writer.finish()
        } catch {
            debugPrint("writer failure", error)
            return
        }

        guard let containerURL = self.fileManager.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.metaic.screenrecorder"
        )?.appendingPathComponent("Library/Documents/") else {
            fatalError("no container directory")
        }
        do {
            try self.fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            debugPrint("error creating", containerURL, error)
        }

        let destination = containerURL.appendingPathComponent(outputURL.lastPathComponent)
        do {
            debugPrint("Moving", outputURL, "to:", destination)
            try self.fileManager.moveItem(
                at: outputURL,
                to: destination
            )
            self.userDefault?.set(0, forKey: "broadcast")
            if self.isBroadcast {
                self.userDefault?.set(0, forKey: "stream")
            }
        } catch {
            debugPrint("ERROR", error)
        }

        debugPrint("FINISHED")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard let writer = self.writer else {
            debugPrint("processSampleBuffer: Writer is nil")
            return
        }

        do {
            let captured = try writer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
            debugPrint("processSampleBuffer captured", captured)
        } catch {
            debugPrint("processSampleBuffer error:", error.localizedDescription)
        }
        
        if self.isBroadcast {
            self.streamer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
        }
    }
    
    private func scheduleNotification() {
        let content: UNMutableNotificationContent = .init()
        content.title = "broadcastStarted"
        content.subtitle = Date().description

        let trigger: UNNotificationTrigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
        let notificationRequest: UNNotificationRequest = .init(
            identifier: "group.com.metaic.screenrecorder.notification",
            content: content,
            trigger: trigger
        )
        self.notificationCenter.add(notificationRequest) { (error) in
            print("add", notificationRequest, "with ", error?.localizedDescription ?? "no error")
        }
    }
}

extension SampleHandler: ScreencasterDelegate {
    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable : Any]!) {
        print("connectionStateDidChange \(id) state: \(state.rawValue) status: \(status.rawValue)")
    }
}

extension FileManager {

    func removeFileExists(url: URL) {
        guard fileExists(atPath: url.path) else { return }
        do {
            try removeItem(at: url)
        } catch {
            print("error removing item \(url)", error)
        }
    }
}

