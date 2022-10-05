//
//  UIImage+Ext.swift
//  OlaChat
//
//  Created by Rum on 10/12/2020.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit
import Photos

extension CIImage {
    func resizeCI(scaleSize: CGSize) -> CIImage? {
        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!

        // Compute scale and corrective aspect ratio
        var scale: CGFloat = 0
        var aspectRatio: CGFloat = 0
        if self.extent.width > self.extent.height {
            scale = scaleSize.width / self.extent.width
            aspectRatio = scaleSize.width/(self.extent.width * scale)
        } else {
            scale = scaleSize.height / self.extent.height
            aspectRatio = scaleSize.height/(self.extent.height * scale)
        }

        // Apply resizing
        resizeFilter.setValue(self, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        let outputImage = resizeFilter.outputImage
        return outputImage
    }
}


@available(iOS 13.0, *)
extension UIImage {
    func createTabBarIndicator(color: UIColor, size: CGSize, lineWidth: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: lineWidth))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func resizeForAvatarImage() -> UIImage {
        let widthRatio  = self.size.width  / self.size.height
        let heightRatio =  self.size.height /  self.size.width
        var newSize: CGSize = .zero
        let targetSize: CGFloat = 1080

        if self.size.width < targetSize || self.size.height < targetSize {
            return self
        } else {
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: targetSize * widthRatio, height: targetSize)
            } else {
                newSize = CGSize(width: targetSize, height: targetSize * heightRatio)
            }
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in:rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }
    
    func resizeImage(qualityHD: Bool) -> UIImage {
        // Define in App: 1080 for Non HD, 4096 for HD
        let widthRatio  = self.size.width  / self.size.height
        let heightRatio =  self.size.height /  self.size.width
        var newSize: CGSize = .zero
        let targetSize: CGFloat = qualityHD ? 1080 : 640

        if self.size.width < targetSize || self.size.height < targetSize {
            return self
        } else {
            if(widthRatio > heightRatio) {
                newSize = CGSize(width: targetSize * widthRatio, height: targetSize)
            } else {
                newSize = CGSize(width: targetSize, height: targetSize * heightRatio)
            }
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in:rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in:rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }
    
    func resizeImage(maxSize: CGSize) -> UIImage {
        
        let size = self.size
        
        if (size.width < maxSize.width && size.height < maxSize.height) {
            return self
        }
        
        let widthRatio  = maxSize.width  / size.width
        let heightRatio = maxSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }

    func createThumbnailForImage(multi: Bool = false) -> UIImage {
        guard let imageData = self.pngData() else {
            return UIImage()
        }
        
        let pixel = multi ? 450 : 650
        
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: pixel] as CFDictionary
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
        let thumbnail = UIImage(cgImage: imageReference)
        return thumbnail
    }
    
    func gif(asset: String) -> UIImage? {
        if let asset = NSDataAsset(name: asset) {
            return UIImage(data: asset.data)
        }
        return nil
    }
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
            break
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
            
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
            
        default:
            break
        }
        
        let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: self.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.height), height: CGFloat(size.width)))
            break
            
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(size.width), height: CGFloat(size.height)))
            break
        }
        
        let cgimg: CGImage = (ctx?.makeImage())!
        let img = UIImage(cgImage: cgimg)
        
        return img
    }
    
    func addToCenter(of superView: UIView, width: CGFloat = 68, height: CGFloat = 68, cornerRadius: CGFloat = 24) {
        superView.subviews.forEach {$0.removeFromSuperview()}
        
        let overlayView = UIView()
        overlayView.backgroundColor = .white
        overlayView.cornerRadius = cornerRadius
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.clipsToBounds = true

        superView.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: superView.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: superView.centerYAnchor),
            overlayView.widthAnchor.constraint(equalToConstant: width),
            overlayView.heightAnchor.constraint(equalToConstant: height)
        ])
        
        let overlayImageView = UIImageView(image: self)
        overlayImageView.contentMode = .scaleAspectFit
        overlayView.addSubview(overlayImageView)
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayImageView.topAnchor.constraint(equalTo: overlayView.topAnchor, constant: 6),
            overlayImageView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -6),
            overlayImageView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 6),
            overlayImageView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -6)
        ])
    }
    
    func toPngString() -> String? {
        let data = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
  
    func toJpegString(compressionQuality cq: CGFloat) -> String? {
        let data = self.jpegData(compressionQuality: cq)
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
    
    func compressTo(_ expectSize: Double) -> Data? {
        let sizeInBytes = expectSize * 1024
        var needCompress: Bool = true
        var imgData: Data?
        var compressingValue: CGFloat = 1.0
        while (needCompress && compressingValue > 0.0) {
            if let data: Data = self.jpegData(compressionQuality: compressingValue) {
                if data.count < Int(sizeInBytes) {
                    needCompress = false
                    imgData = data
                } else {
                    compressingValue -= 0.1
                }
            }
        }

        if let data = imgData {
            return data
        }
            return nil
        }
    }

struct Downsampler {
    static func downsampleImage(imageURL: URL, frameSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOption) else {
            return nil
        }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(frameSize.width, frameSize.height) * scale
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}
