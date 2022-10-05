//
//  Countdown.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class Countdown {
    weak var delegate: CountdownDelegate?
    
    private var currentValue: Int = 0 {
        didSet {
            delegate?.updateCounterValue(newValueString: currentValue.durationToShortString())
            delegate?.updateCounterValue(newValue: currentValue)
        }
    }
    
    public func getSecondsCountdown() -> String {
        return String(format: "%i", currentValue)
    }
    
    public var useMinutesAndSeconds = true
    
    private var timer: Timer?
    private var beginValue: Int = 1
    private var totalTime: TimeInterval = 1
    private var elapsedTime: TimeInterval = 0
    private var timeInterval: TimeInterval = 1
    private let fireTime: TimeInterval = 0.01
    var isCountDown: Bool = true
    
    private func getSecondsAndMinutes(remainingSeconds: Int) -> (String) {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds - minutes * 60
        let secondString = seconds < 10 ? "0" + seconds.description : seconds.description
        return minutes.description + ":" + secondString
    }
    
    public func pauseCountdown() {
        timer?.fireDate = Date.distantFuture
        
        delegate?.pause()
    }
    
    public func startCountdown(beginingValue: Int, interval: TimeInterval = 1, countDown: Bool = true) {
        self.beginValue = beginingValue
        self.timeInterval = interval
        self.isCountDown = countDown
        
        totalTime = TimeInterval(beginingValue) * interval
        elapsedTime = 0
        currentValue = beginingValue
        
        timer?.invalidate()
        timer = Timer(timeInterval: fireTime, target: self, selector: #selector(Countdown.timerFiredInterval(_:)), userInfo: nil, repeats: true)
        
        RunLoop.main.add(timer!, forMode: .common)
        
        delegate?.start()
    }
    
    public func endCountdown() {
        self.currentValue = 0
        timer?.invalidate()
        
        delegate?.end()
    }
    
    public func resumeCountdown() {
        timer?.fireDate = Date()
        
        delegate?.resume()
    }
    
    public func invalidate() {
        timer?.invalidate()
    }
    
    @objc private func timerFiredInterval(_ timer: Timer) {
        if isCountDown {
            elapsedTime += fireTime
            
            if elapsedTime < totalTime {
                let computedCounterValue = beginValue - Int(elapsedTime / timeInterval)
                if computedCounterValue != currentValue {
                    currentValue = computedCounterValue
                }
            } else {
                endCountdown()
            }
        } else {
            elapsedTime += fireTime
            let computedCounterValue = beginValue + Int(elapsedTime / timeInterval)
            currentValue = computedCounterValue
        }
        
    }
}

protocol CountdownDelegate: AnyObject {
    func updateCounterValue(newValue: Int)
    func updateCounterValue(newValueString: String)
    func start()
    func pause()
    func resume()
    func end()
}
