//
//  VideoPostprocessorVImage.swift
//  Broadcast_Livestream
//
//  Created by htv on 22/08/2022.
//

import Foundation
import Accelerate

class VideoPostprocessorVImage: VideoPostprocessor {

    static private let PixelFormat_YUV = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    private var tmpBufferY: UnsafeMutableRawPointer?
    private var tmpBufferUV: UnsafeMutableRawPointer?
    private var active = false
    private var prevFrameWidth: vImagePixelCount = 0
    private var prevFrameHeight: vImagePixelCount = 0

    override func start() -> Bool {
        active = true
        return true
    }
    
    override func stop() {
        active = false
        tmpBufferY?.deallocate()
        tmpBufferUV?.deallocate()
        tmpBufferY = nil
        tmpBufferUV = nil
    }
    
    override func rotateAndEncode(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        if active == false {
            return nil
        }
        var outputBuffer: CVPixelBuffer?
        guard let sourceBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return nil}
        let rotation = getRotation(orientation: orientation)
        
        if rotation == kRotate0DegreesClockwise {
            outputBuffer = scale(sourceBuffer)
        } else {
            outputBuffer = scaleAndRotate(sourceBuffer: sourceBuffer, rotation: rotation)
        }
        return outputBuffer
    }
    
    private func scale(_ sourceBuffer: CVImageBuffer) -> CVPixelBuffer? {
//        let t0 = CACurrentMediaTime()
        var outputBuffer: CVPixelBuffer?

        var status = CVPixelBufferCreate(kCFAllocatorDefault, streamWidth, streamHeight, Self.PixelFormat_YUV, nil, &outputBuffer)
        if status != kCVReturnSuccess || outputBuffer == nil {
            return nil
        }
        
        status = CVPixelBufferLockBaseAddress(sourceBuffer, .readOnly)
        if (status == kCVReturnSuccess) {
            status = CVPixelBufferLockBaseAddress(outputBuffer!, [])
        }
        if status != kCVReturnSuccess  {
            return nil
        }

        var srcY = Self.getVBufferFull(sourceBuffer, plane: 0)
        var srcUV = Self.getVBufferFull(sourceBuffer, plane: 1)
        var dstY = Self.getVBufferCentered(outputBuffer!, plane: 0, sourceW: srcY.width, sourceH: srcY.height)
        var dstUV = Self.getVBufferCentered(outputBuffer!, plane: 1, sourceW: srcUV.width, sourceH: srcUV.height)
        var imageError = Self.fillBlack(outputBuffer!)

        allocateTempBuffers(srcY: srcY, srcUV: srcUV, dstY: dstY, dstUV: dstUV)

        if imageError == kvImageNoError {
            imageError = vImageScale_Planar8(&srcY, &dstY, tmpBufferY, vImage_Flags(kvImageNoAllocate))
        }
        if imageError == kvImageNoError {
            imageError = vImageScale_CbCr8(&srcUV, &dstUV, tmpBufferUV, vImage_Flags(kvImageNoAllocate))
        }

        CVPixelBufferUnlockBaseAddress(outputBuffer!, [])
        CVPixelBufferUnlockBaseAddress(sourceBuffer, .readOnly)
        if imageError != kvImageNoError {
            outputBuffer = nil
        }
//        let t1 = CACurrentMediaTime()
//        let dt = round((t1-t0) * 1000)
//        DDLogVerbose("Scaling done in \(dt) ms")
        return outputBuffer
    }
        
    private func scaleAndRotate(sourceBuffer: CVImageBuffer, rotation: Int) -> CVPixelBuffer? {
//        let t0 = CACurrentMediaTime()
        
        let srcW = CVPixelBufferGetWidth(sourceBuffer)
        let srcH = CVPixelBufferGetHeight(sourceBuffer)

        var scaleW = streamWidth
        var scaleH = streamHeight
        let swapWidthHeight = rotation == kRotate90DegreesClockwise || rotation == kRotate270DegreesClockwise ||
            rotation == kRotate90DegreesCounterClockwise || rotation == kRotate270DegreesCounterClockwise

        if swapWidthHeight {
            (scaleW,scaleH) = (scaleH,scaleW)
        }
        let scale = min(Float(scaleW)/Float(srcW), Float(scaleH)/Float(srcH))
        scaleW = Int((Float(srcW) * scale).rounded())
        scaleH = Int((Float(srcH) * scale).rounded())
        
        var scaleBuffer: CVPixelBuffer?

        var status = CVPixelBufferCreate(kCFAllocatorDefault, scaleW, scaleH, Self.PixelFormat_YUV, nil, &scaleBuffer)
        if status != kCVReturnSuccess || scaleBuffer == nil {
            return nil
        }

        CVPixelBufferLockBaseAddress(sourceBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(scaleBuffer!, [])
        
        var srcY = Self.getVBufferFull(sourceBuffer, plane: 0)
        var srcUV = Self.getVBufferFull(sourceBuffer, plane: 1)
        var scaleY = Self.getVBufferFull(scaleBuffer!, plane: 0)
        var scaleUV = Self.getVBufferFull(scaleBuffer!, plane: 1)
        var imageError: vImage_Error = kvImageNoError
        allocateTempBuffers(srcY: srcY, srcUV: srcUV, dstY: scaleY, dstUV: scaleUV)

        if imageError == kvImageNoError {
            imageError = vImageScale_Planar8(&srcY, &scaleY, tmpBufferY, vImage_Flags(kvImageNoAllocate))
        }
        if imageError == kvImageNoError {
            imageError = vImageScale_CbCr8(&srcUV, &scaleUV, tmpBufferUV, vImage_Flags(kvImageNoAllocate))
        }
        CVPixelBufferUnlockBaseAddress(sourceBuffer, .readOnly)
        var outputBuffer: CVPixelBuffer?
        if (imageError == kvImageNoError) {
            status = CVPixelBufferCreate(kCFAllocatorDefault, streamWidth, streamHeight, Self.PixelFormat_YUV, nil, &outputBuffer)
        }
        if status != kCVReturnSuccess || outputBuffer == nil {
            CVPixelBufferUnlockBaseAddress(scaleBuffer!, [])
            scaleBuffer = nil
            return nil
        }
        CVPixelBufferLockBaseAddress(outputBuffer!, [])
        var rotateY = Self.getVBufferFull(outputBuffer!, plane: 0)
        var rotateUV = Self.getVBufferFull(outputBuffer!, plane: 1)
        let fillY: UInt8 = 0
        let fillUV: UInt16 = 0x8080
        imageError = vImageRotate90_Planar8(&scaleY, &rotateY, UInt8(rotation), fillY, 0)
        if imageError == kvImageNoError {
            vImageRotate90_Planar16U(&scaleUV, &rotateUV, UInt8(rotation), fillUV, 0)
        }
        CVPixelBufferUnlockBaseAddress(scaleBuffer!, [])
        CVPixelBufferUnlockBaseAddress(outputBuffer!, [])
//        let t1 = CACurrentMediaTime()
//        let dt = round((t1-t0) * 1000)
//        DDLogVerbose("Scaling done in \(dt) ms")
        return outputBuffer
    }
    
    private func allocateTempBuffers(srcY: vImage_Buffer, srcUV: vImage_Buffer, dstY: vImage_Buffer, dstUV: vImage_Buffer ) {
        let w = dstY.width
        let h = dstY.height
        if prevFrameWidth != w || prevFrameHeight != h {
            tmpBufferY?.deallocate()
            tmpBufferUV?.deallocate()
            tmpBufferY = nil
            tmpBufferUV = nil
            prevFrameWidth = w
            prevFrameHeight = h
        }
        
        if tmpBufferY == nil {
            var srcY_ = srcY
            var dstY_ = dstY
            let size = vImageScale_Planar8(&srcY_, &dstY_, nil, vImage_Flags(kvImageGetTempBufferSize))
            if size > 0 {
                tmpBufferY = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 4)
            }
        }
        if tmpBufferUV == nil {
            var srcUV_ = srcUV
            var dstUV_ = dstUV
            let size = vImageScale_CbCr8(&srcUV_, &dstUV_, nil, vImage_Flags(kvImageGetTempBufferSize))
            if size > 0 {
                tmpBufferUV = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 4)
            }
        }
    }
    
    private class func getVBufferFull(_ sourceBuffer: CVPixelBuffer, plane: Int) -> vImage_Buffer {
        let w = CVPixelBufferGetWidthOfPlane(sourceBuffer, plane)
        let h = CVPixelBufferGetHeightOfPlane(sourceBuffer, plane)
        let row = CVPixelBufferGetBytesPerRowOfPlane(sourceBuffer, plane)
        let ptr = CVPixelBufferGetBaseAddressOfPlane(sourceBuffer, plane)
        
        return vImage_Buffer(data: ptr, height: vImagePixelCount(h), width: vImagePixelCount(w), rowBytes: row)
    }

    private class func getVBufferCentered(_ sourceBuffer: CVPixelBuffer, plane: Int, sourceW: vImagePixelCount, sourceH: vImagePixelCount) -> vImage_Buffer {
        var w = CVPixelBufferGetWidthOfPlane(sourceBuffer, plane)
        var h = CVPixelBufferGetHeightOfPlane(sourceBuffer, plane)
        let row = CVPixelBufferGetBytesPerRowOfPlane(sourceBuffer, plane)
        guard var ptr = CVPixelBufferGetBaseAddressOfPlane(sourceBuffer, plane) else {return vImage_Buffer()}
        let step = plane == 0 ? 1 : 2 //1 byte for Y, 2 bytes for UV
        var gapX = 0
        var gapY = 0
        let scaleX = Float(w) / Float(sourceW)
        let scaleY = Float(h) / Float(sourceH)
        if scaleX < scaleY {
            let h0 = h
            h = Int(Float(sourceH) * scaleX)
            gapY = (h0 - h) / 2
        } else {
            let w0 = w
            w = Int(Float(sourceW) * scaleY)
            gapX = (w0 - w) / 2
        }
        let offset = gapX * step + gapY * row
        ptr += offset

        return vImage_Buffer(data: ptr, height: vImagePixelCount(h), width: vImagePixelCount(w), rowBytes: row)
    }
    
    private class func fillBlack(_ buffer: CVPixelBuffer) -> vImage_Error {
        let dstYFill = getVBufferFull(buffer, plane: 0)
        let colorY:Int32 = 0
        let fillCount = Int(dstYFill.rowBytes * Int(dstYFill.height))
        if fillCount <= 0 || dstYFill.data == nil {
            return kvImageInvalidParameter
        }
        memset(dstYFill.data, colorY, fillCount)
        var dstUVFill = getVBufferFull(buffer, plane: 1)
        var colorUV: [UInt8] = [128, 128]
        return vImageBufferFill_CbCr8(&dstUVFill, &colorUV, UInt32(kvImageNoFlags))
    }
    
    private func getRotation(orientation: CGImagePropertyOrientation) -> Int {
        var rotation = kRotate0DegreesClockwise
        switch (orientation) {
        case .left, .leftMirrored:
            rotation = kRotate90DegreesClockwise
            
        case .right, .rightMirrored:
            rotation = kRotate90DegreesCounterClockwise

        case .up, .upMirrored:
            rotation = kRotate0DegreesClockwise

        case .down, .downMirrored:
            rotation = kRotate180DegreesClockwise

        default:
            break
        }
        return rotation
    }
    
    class func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBufer: CVPixelBuffer?

        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width, height,
                                         PixelFormat_YUV,
                                         nil,
                                         &pixelBufer)
        
        guard status == kCVReturnSuccess, pixelBufer != nil else {
            return nil
        }
        if fillBlack(pixelBufer!) != kvImageNoError {
        }
        
        return pixelBufer
    }

}


