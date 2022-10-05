//
//  UISegmentedControl+ext.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

extension UISegmentedControl {
    func replaceSegment(segments: Array<String>) {
        self.removeAllSegments()
        for segment in segments {
            self.insertSegment(withTitle: segment, at: self.numberOfSegments, animated: false)
        }
    }
}
