//
//  Model.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit

struct VideoModel: Equatable {
    var url: URL
    var name: String
    var thumb: CGImage?
    var duration: Double
    var createAt: Date
}

struct ProductModel: Equatable {
    var name: String
    var price: String
}
