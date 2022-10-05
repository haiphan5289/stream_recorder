//
//  MonochromeEffect.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import HaishinKit
import CoreMedia

class MonochromeEffect: VideoEffect {
    let ciFilter: CIFilter? = CIFilter(name: "CIColorMonochrome")
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = ciFilter else {
            return image
        }
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: "inputColor")
        filter.setValue(1.0, forKey: "inputIntensity")
        return filter.outputImage!
    }
}
