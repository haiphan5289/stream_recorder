//
//  VideoPostprocessor.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation
import CoreImage
import ReplayKit

class VideoPostprocessor {
    public var verticalStream: Bool = false
    public var videoSize: CMVideoDimensions = CMVideoDimensions(width: 750, height: 1344)
    public var streamWidth: Int = 750
    public var streamHeight: Int = 1344
    
    func start() -> Bool {
        return false
    }
    
    func stop()  {
    }
    
    func rotateAndEncode(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        return nil
    }
}

class VideoPostprocessorCoreImage: VideoPostprocessor {

    private var ciContext: CIContext?
    static private let PixelFormat_RGB = kCVPixelFormatType_32ARGB
    
    var outputImage: CIImage?
    
    var wCam: CGFloat {
        return CGFloat(videoSize.width)
    }
    
    var hCam: CGFloat {
        return CGFloat(videoSize.height)
    }
    
    var scaleValue: CGFloat {
        return wCam / hCam
    }
    
    var gap: CGFloat {
        return (hCam - (wCam * scaleValue)) / 2
    }

    override func start() -> Bool {
        let options = [CIContextOption.workingColorSpace: NSNull(),
                       CIContextOption.outputColorSpace: NSNull(),
                       CIContextOption.useSoftwareRenderer: NSNumber(value: false),
                       CIContextOption.cacheIntermediates: NSNumber(value: false)]
        ciContext = CIContext(options: options)
        return ciContext != nil
    }
    
    override func stop() {
        ciContext?.clearCaches()
        ciContext = nil
    }
    
    override func rotateAndEncode(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        let t0 = CACurrentMediaTime()

        guard let outputBuffer: CVPixelBuffer = Self.createPixelBuffer(width: streamWidth, height: streamHeight) else {
            return nil
        }
        
        let sourceBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer, options: [CIImageOption.colorSpace: NSNull()])
        
        outputImage = sourceImage
        //DDLogDebug("output \(streamWidth) x \(streamHeight) scale: \(scaleValue); gap: \(gap)")
        doTransform(orientation: orientation)
        
        if let context = ciContext, let image = outputImage {
            //DDLogDebug("render \(image.extent.width) x \(image.extent.height)")
            context.render(image, to: outputBuffer, bounds: image.extent, colorSpace: nil)
        }
        let t1 = CACurrentMediaTime()
        let dt = round((t1-t0) * 1000)
        return outputBuffer
    }
    
    func doTransform(orientation: CGImagePropertyOrientation) {
        if verticalStream {
            switch (orientation) {
            case .left, .leftMirrored:
                rotateLeft()
                scale()
                centerVertically()
                
            case .right, .rightMirrored:
                rotateRight()
                scale()
                centerVertically()
                
            case .up, .upMirrored:
                break
                
            case .down, .downMirrored:
                flip()
                
            default:
                break
            }
            
        } else {
            switch (orientation) {
            case .left, .leftMirrored:
                rotateLeft()
                
            case .right, .rightMirrored:
                rotateRight()

            case .down, .downMirrored:
                flip()
                fallthrough
            case .up, .upMirrored:
                scale()
                centerHorizontally()
            default:
                break
            }
        }
        
    }
    
    func flip() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(scaleX: -1, y: 1))
                        .transformed(by: CGAffineTransform.init(translationX: outputImage!.extent.width, y: 0))
        
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(scaleX: 1, y: -1))
                        .transformed(by: CGAffineTransform.init(translationX: 0, y: outputImage!.extent.size.height))
    }
    
    func rotateLeft() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(rotationAngle: CGFloat(-Double.pi / 2)))
                        .transformed(by: CGAffineTransform.init(translationX: 0, y: wCam))
    }
    
    func rotateRight() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(rotationAngle: CGFloat(Double.pi / 2)))
            .transformed(by: CGAffineTransform.init(translationX: hCam, y: 0))
    }
    
    func scale() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(scaleX: scaleValue, y: scaleValue))
    }
    
    func centerVertically() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(translationX: 0, y: gap))
    }
    
    func centerHorizontally() {
        outputImage = outputImage!.transformed(by: CGAffineTransform.init(translationX: gap, y: 0))
    }
    
    class func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBufer: CVPixelBuffer?

        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width, height,
                                         PixelFormat_RGB,
                                         outputOptions as CFDictionary?,
                                         &pixelBufer)
        
        guard status == kCVReturnSuccess, pixelBufer != nil else {
            return nil
        }
        return pixelBufer
        
    }
}


