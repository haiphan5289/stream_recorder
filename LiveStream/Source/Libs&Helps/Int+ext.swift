//
//  Int+ext.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

extension Int {
    func secondToHourMinuteSecond() -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    func durationToShortString() -> String {
        let (h, m, s) = self.secondToHourMinuteSecond()
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func secondToMinuteSecond() -> (Int, Int) {
        return ((self % 3600) / 60, (self % 3600) % 60)
    }
    
    func durationToString() -> String {
        let (m, s) = self.secondToMinuteSecond()
        return String(format: "%02d:%02d", m, s)
    }
    
}
