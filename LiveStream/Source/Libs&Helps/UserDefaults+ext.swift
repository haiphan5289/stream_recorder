//
//  UserDefaults+ext.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

extension UserDefaults {
    @objc dynamic var broadcast: Int {
        return integer(forKey: "broadcast")
    }
    @objc dynamic var stream: Int {
        return integer(forKey: "stream")
    }
}
