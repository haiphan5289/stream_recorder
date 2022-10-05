//
//  StreamConditioner.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation


class LossHistory {
    var ts: CFTimeInterval
    var audio: UInt64
    var video: UInt64
    
    init(ts: CFTimeInterval, audio: UInt64, video: UInt64) {
        self.ts = ts
        self.audio = audio
        self.video = video
    }
}

class BitrateHistory {
    var ts: CFTimeInterval
    var bitrate: Double
    
    init(ts: CFTimeInterval, bitrate: Double) {
        self.ts = ts
        self.bitrate = bitrate
    }
}

protocol StreamConditioner {
    func start(bitrate: Int, id: [Int32])
    func stop()
    func addConnection(id: Int32)
    func removeConnection(id: Int32)
}

class StreamConditionerBase: StreamConditioner {
    
    var currentBitrate: Double = 0
    var lossHistory: [LossHistory] = []
    var bitrateHistory: [BitrateHistory] = []
    
    var connectionId:Set<Int32> = []
    
    var checkTimer: Timer?
    
    func start(bitrate: Int, id: [Int32]) {
        guard id.count > 0 else {
            return
        }
        stop()
        
        currentBitrate = Double(bitrate)
        connectionId = Set(id)
        
        let curTime = CACurrentMediaTime()
        lossHistory.append(LossHistory(ts: curTime, audio: 0, video: 0))
        bitrateHistory.append(BitrateHistory(ts: curTime, bitrate: currentBitrate))
        
        checkTimer?.invalidate()
        let firstCheckTime = Date(timeIntervalSinceNow: checkDelay())
        checkTimer = Timer(fire: firstCheckTime, interval: checkInterval(), repeats: true, block: { (_) in
            self.checkNetwork()
        })
        RunLoop.main.add(checkTimer!, forMode: .common)
    }
    
    func checkNetwork() {
        guard connectionId.count > 0 else {
            return
        }
        var audioLost: UInt64 = 0
        var videoLost: UInt64 = 0
        for id in connectionId {
            audioLost += ScreenStreamer.sharedInstance.audioPacketsLost(connection: id)
            videoLost += ScreenStreamer.sharedInstance.videoPacketsLost(connection: id)
            videoLost += ScreenStreamer.sharedInstance.udpPacketsLost(connection: id)
        }
        check(audioLost: audioLost, videoLost: videoLost)
    }
    
    func stop() {
        checkTimer?.invalidate()
        lossHistory.removeAll()
        bitrateHistory.removeAll()
        connectionId.removeAll()
    }
    
    func addConnection(id: Int32) {
        guard id != -1 else {
            return
        }
        connectionId.insert(id)
    }
    
    func removeConnection(id: Int32) {
        connectionId.remove(id)
    }
    
    func check(audioLost: UInt64, videoLost: UInt64) {
        
    }
    
    func countLostFor(interval: CFTimeInterval) -> UInt64 {
        var lostPackets: UInt64 = 0
        if let last = lossHistory.last {
            for i in lossHistory.indices.dropLast() {
                let h = lossHistory[i]
                if h.ts < interval {
                    lostPackets = (last.video - h.video) + (last.audio - h.audio)
                    break
                }
            }
        }
        return lostPackets
    }
    
    func changeBitrate(newBitrate: Double) {
        let curTime = CACurrentMediaTime()
        bitrateHistory.append(BitrateHistory(ts: curTime, bitrate: newBitrate))
        ScreenStreamer.sharedInstance.changeBitrate(newBitrate: Int32(newBitrate))
        currentBitrate = newBitrate
    }
    
    func changeBitrateQuiet(newBitrate: Double) {
        ScreenStreamer.sharedInstance.changeBitrate(newBitrate: Int32(newBitrate))
    }
    
    func checkInterval() -> TimeInterval {
        return 0.5
    }
    
    func checkDelay() -> TimeInterval {
        return 1
    }
    
}

class StreamConditionerMode1: StreamConditionerBase {
    
    let NORMALIZATION_DELAY: CFTimeInterval = 1.5 // Ignore lost packets during this time after bitrate change
    let LOST_ESTIMATE_INTERVAL: CFTimeInterval = 10 // Period for lost packets count
    let LOST_TOLERANCE = 4 // Maximum acceptable number of lost packets
    let RECOVERY_ATTEMPT_INTERVAL: CFTimeInterval = 60
    
    var initBitrate: Double = 0
    var minBitrate: Double = 0
    
    override func start(bitrate: Int, id: [Int32]) {
        initBitrate = Double(bitrate)
        minBitrate = initBitrate / 4
        super.start(bitrate: bitrate, id: id)
    }
    
    override func check(audioLost: UInt64, videoLost: UInt64) {
        if let prevLost = lossHistory.last, let prevBitrate = bitrateHistory.last, let firstBitrate = bitrateHistory.first {

            let curTime = CACurrentMediaTime()
            let lastChange = max(prevLost.ts, prevBitrate.ts)
            if prevLost.audio != audioLost, prevLost.video != videoLost {

                let dtChange = curTime - prevBitrate.ts
                if prevBitrate.bitrate <= minBitrate || dtChange < NORMALIZATION_DELAY {
                    return
                }
                lossHistory.append(LossHistory(ts: curTime, audio: audioLost, video: videoLost))
                let estimatePeriod = max(prevBitrate.ts + NORMALIZATION_DELAY, curTime - LOST_ESTIMATE_INTERVAL)
                if countLostFor(interval: estimatePeriod) >= LOST_TOLERANCE {
                    let newBitrate = max(minBitrate, prevBitrate.bitrate * 1000 / 1414)
                    changeBitrate(newBitrate: newBitrate)
                }
            } else if prevBitrate.bitrate != firstBitrate.bitrate, curTime - lastChange >= RECOVERY_ATTEMPT_INTERVAL {
                let newBitrate = min(initBitrate, prevBitrate.bitrate * 1415 / 1000)
                changeBitrate(newBitrate: newBitrate)
            }
        }
    }
    
}

class StreamConditionerMode2: StreamConditionerBase {
    
    let NORMALIZATION_DELAY: CFTimeInterval = 2 // Ignore lost packets during this time after bitrate change
    let LOST_ESTIMATE_INTERVAL: CFTimeInterval = 10 // Period for lost packets count
    let LOST_BANDWITH_TOLERANCE_FRAC: Double = 300000
    let BANDWITH_STEPS: [Double] = [0.2, 0.25, 1.0 / 3.0, 0.450, 0.600, 0.780, 1.000]
    let RECOVERY_ATTEMPT_INTERVALS: [CFTimeInterval] = [15, 60, 60 * 3]
    let DROP_MERGE_INTERVAL: CFTimeInterval // Period for bitrate drop duration
    
    var fullSpeed: Double = 0
    var step = 0
    
    override init() {
        DROP_MERGE_INTERVAL = CFTimeInterval(BANDWITH_STEPS.count) * NORMALIZATION_DELAY * 2
    }
    
    override func start(bitrate: Int, id: [Int32]) {
        fullSpeed = Double(bitrate)
        step = 2
        let startBitrate = round(fullSpeed * BANDWITH_STEPS[step])
        super.start(bitrate: Int(startBitrate), id: id)
        changeBitrateQuiet(newBitrate: startBitrate)
    }
    
    override func check(audioLost: UInt64, videoLost: UInt64) {
        if let prevLost = lossHistory.last, let prevBitrate = bitrateHistory.last {

            let curTime = CACurrentMediaTime()
            if prevLost.audio != audioLost, prevLost.video != videoLost {

                let dtChange = curTime - prevBitrate.ts
                if step == 0 || dtChange < NORMALIZATION_DELAY {
                    return
                }
                lossHistory.append(LossHistory(ts: curTime, audio: audioLost, video: videoLost))
                let estimatePeriod = max(prevBitrate.ts + NORMALIZATION_DELAY, curTime - LOST_ESTIMATE_INTERVAL)
                let lostTolerance = Int(prevBitrate.bitrate / LOST_BANDWITH_TOLERANCE_FRAC)
                if countLostFor(interval: estimatePeriod) >= lostTolerance {
                    step = step - 1
                    let newBitrate = round(fullSpeed * BANDWITH_STEPS[step])
                    changeBitrate(newBitrate: newBitrate)
                }
            } else if Double(prevBitrate.bitrate) < fullSpeed, canTryToRecover() {
                step = step + 1
                let newBitrate = round(fullSpeed * BANDWITH_STEPS[step])
                changeBitrate(newBitrate: newBitrate)
            }
        }
    }
    
    func canTryToRecover() -> Bool {
        let curTime = CACurrentMediaTime()
        let len = bitrateHistory.count
        var numDrops = 0
        let numIntervals = RECOVERY_ATTEMPT_INTERVALS.count
        var prevDropTime: CFTimeInterval = 0
        
        for i in stride(from: len-1, to: 0, by: -1) {
            let last = bitrateHistory[i]
            let prev = bitrateHistory[i-1]
            let dt = curTime - last.ts
            if last.bitrate < prev.bitrate {
                if prevDropTime != 0, prevDropTime - last.ts < DROP_MERGE_INTERVAL {
                    continue
                }
                if dt <= RECOVERY_ATTEMPT_INTERVALS[numDrops] {
                    return false
                }
                numDrops = numDrops + 1
                prevDropTime = last.ts
            }
            
            if numDrops == numIntervals || curTime - last.ts >= RECOVERY_ATTEMPT_INTERVALS[numIntervals - 1] {
                break
            }
        }
        return true
    }
    
    override func checkInterval() -> TimeInterval {
        return 2
    }
    
    override func checkDelay() -> TimeInterval {
        return 2
    }
    
}

