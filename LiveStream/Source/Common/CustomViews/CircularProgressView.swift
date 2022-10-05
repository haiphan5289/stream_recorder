//
//  CircularProgressView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

@objc public enum CircularProgressGlowMode: Int {
    case forward, reverse, constant, noGlow
}

@IBDesignable
@objcMembers
public class CircularProgressView: UIView, CAAnimationDelegate {
    private var progressLayerCPView: CircularProgressLayer {
        get {
            return layer as! CircularProgressLayer
        }
    }
    
    private var radiusCPView: CGFloat = 0.0 {
        didSet {
            progressLayerCPView.radiusCPLayer = radiusCPView
        }
    }
    
    public var progressCPView: Double {
        get { return angleCPView.modFloatingPointCPView(between: 0.0, and: 360.0, byIncrementing: 360.0) / 360.0 }
        set { angleCPView = newValue.clampComparableCPView(lowerBound: 0.0, upperBound: 1.0) * 360.0 }
    }
    
    @IBInspectable public var angleCPView: Double = 0.0 {
        didSet {
            pauseAnimatingCPView()
            progressLayerCPView.angleCPView = angleCPView
        }
    }
    
    @IBInspectable public var startAngleCPView: Double = 0.0 {
        didSet {
            startAngleCPView = startAngleCPView.modFloatingPointCPView(between: 0.0, and: 360.0, byIncrementing: 360.0)
            progressLayerCPView.startAngleCPLayer = startAngleCPView
            progressLayerCPView.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var clockwiseCPView: Bool = true {
        didSet {
            progressLayerCPView.clockwiseCPLayer = clockwiseCPView
            progressLayerCPView.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var roundedCornersCPView: Bool = true {
        didSet {
            progressLayerCPView.roundedCornersCPLayer = roundedCornersCPView
        }
    }
    
    @IBInspectable public var lerpColorModeCPView: Bool = false {
        didSet {
            progressLayerCPView.lerpColorModeCPLayer = lerpColorModeCPView
        }
    }
    
    @IBInspectable public var gradientRotateSpeedCPView: CGFloat = 0.0 {
        didSet {
            progressLayerCPView.gradientRotateSpeedCPLayer = gradientRotateSpeedCPView
        }
    }
    
    @IBInspectable public var glowAmountCPView: CGFloat = 1.0 {
        didSet {
            glowAmountCPView = glowAmountCPView.clampComparableCPView(lowerBound: 0.0, upperBound: 1.0)
            progressLayerCPView.glowAmountCPLayer = glowAmountCPView
        }
    }
    
    public var glowModeCPView: CircularProgressGlowMode = .forward {
        didSet {
            progressLayerCPView.glowModeCPLayer = glowModeCPView
        }
    }
    
    @IBInspectable public var progressThicknessCPView: CGFloat = 0.4 {
        didSet {
            progressThicknessCPView = progressThicknessCPView.clampComparableCPView(lowerBound: 0.0, upperBound: 1.0)
            progressLayerCPView.progressThicknessCPLayer = progressThicknessCPView / 2.0
        }
    }
    
    @IBInspectable public var trackThicknessCPView: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThicknessCPView = trackThicknessCPView.clampComparableCPView(lowerBound: 0.0, upperBound: 1.0)
            progressLayerCPView.trackThicknessCPLayer = trackThicknessCPView / 2.0
        }
    }
    
    @IBInspectable public var trackColorCPView: UIColor = .black {
        didSet {
            progressLayerCPView.trackColorCPLayer = trackColorCPView
            progressLayerCPView.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var progressInsideFillColorCPView: UIColor? = nil {
        didSet {
            progressLayerCPView.progressInsideFillColorCPLayer = progressInsideFillColorCPView ?? .clear
        }
    }
    
    public var progressColorsCPView: [UIColor] {
        get { return progressLayerCPView.colorsArrayCPLayer }
        set { setCPView(colors: newValue) }
    }
    
    //These are used only from the Interface-Builder. Changing these from code will have no effect.
    //Also IB colors are limited to 3, whereas programatically we can have an arbitrary number of them.
    @objc @IBInspectable private var IBColor1CPView: UIColor?
    @objc @IBInspectable private var IBColor2CPView: UIColor?
    @objc @IBInspectable private var IBColor3CPView: UIColor?
    
    private var animationCompletionBlockCPView: ((Bool) -> Void)?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setInitValuesCPView()
        refreshValuesCPView()
    }
    
    convenience public init(frame:CGRect, colors: UIColor...) {
        self.init(frame: frame)
        setCPView(colors: colors)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        translatesAutoresizingMaskIntoConstraints = false
        setInitValuesCPView()
        refreshValuesCPView()
    }
    
    public override func awakeFromNib() {
        checkAndSetIBColorsCPView()
    }
    
    override public class var layerClass: AnyClass {
        return CircularProgressLayer.self
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        radiusCPView = (frame.size.width / 2.0) * 0.8
    }
    
    private func setInitValuesCPView() {
        radiusCPView = (frame.size.width / 2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        backgroundColor = .clear
        setColorsCPView(colors: .white, .cyan)
    }
    
    private func refreshValuesCPView() {
        progressLayerCPView.angleCPView = angleCPView
        progressLayerCPView.startAngleCPLayer = startAngleCPView
        progressLayerCPView.clockwiseCPLayer = clockwiseCPView
        progressLayerCPView.roundedCornersCPLayer = roundedCornersCPView
        progressLayerCPView.lerpColorModeCPLayer = lerpColorModeCPView
        progressLayerCPView.gradientRotateSpeedCPLayer = gradientRotateSpeedCPView
        progressLayerCPView.glowAmountCPLayer = glowAmountCPView
        progressLayerCPView.glowModeCPLayer = glowModeCPView
        progressLayerCPView.progressThicknessCPLayer = progressThicknessCPView / 2.0
        progressLayerCPView.trackColorCPLayer = trackColorCPView
        progressLayerCPView.trackThicknessCPLayer = trackThicknessCPView / 2.0
    }
    
    private func checkAndSetIBColorsCPView() {
        let IBColors = [IBColor1CPView, IBColor2CPView, IBColor3CPView].compactMap { $0 }
        if IBColors.isEmpty == false {
            setCPView(colors: IBColors)
        }
    }
    
    public func setColorsCPView(colors: UIColor...) {
        setCPView(colors: colors)
    }
    
    private func setCPView(colors: [UIColor]) {
        progressLayerCPView.colorsArrayCPLayer = colors
        progressLayerCPView.setNeedsDisplay()
    }
    
    public func animateCPView(fromAngle: Double, toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        pauseAnimatingCPView()
        let animationDuration: TimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = (toAngle - fromAngle).modFloatingPointCPView(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let scaledDuration = TimeInterval(traveledAngle) * duration / 360.0
            animationDuration = scaledDuration
        }
        
        let animation = CABasicAnimation(keyPath: #keyPath(CircularProgressLayer.angleCPView))
        animation.fromValue = fromAngle
        animation.toValue = toAngle
        animation.duration = animationDuration
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        angleCPView = toAngle
        animationCompletionBlockCPView = completion
        
        progressLayerCPView.add(animation, forKey: "angle")
    }
    
    public func animateCPView(toAngle: Double, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        pauseAnimatingCPView()
        animateCPView(fromAngle: angleCPView, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimationCPView() {
        guard let presentationLayer = progressLayerCPView.presentation() else { return }
        
        let currentValue = presentationLayer.angleCPView
        progressLayerCPView.removeAllAnimations()
        angleCPView = currentValue
    }
    
    private func pauseAnimatingCPView() {
        if isAnimatingCPView() {
            pauseAnimationCPView()
        }
    }
    
    public func stopAnimationCPView() {
        progressLayerCPView.removeAllAnimations()
        angleCPView = 0
    }
    
    public func isAnimatingCPView() -> Bool {
        return progressLayerCPView.animation(forKey: "angle") != nil
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        animationCompletionBlockCPView?(flag)
        animationCompletionBlockCPView = nil
    }
    
    public override func didMoveToWindow() {
        window.map { progressLayerCPView.contentsScale = $0.screen.scale }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            pauseAnimatingCPView()
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        setInitValuesCPView()
        refreshValuesCPView()
        checkAndSetIBColorsCPView()
        progressLayerCPView.setNeedsDisplay()
    }
    
    private class CircularProgressLayer: CALayer {
        @NSManaged var angleCPView: Double
        var radiusCPLayer: CGFloat = 0.0 {
            didSet { invalidateGradientCacheCPLayer() }
        }
        var startAngleCPLayer: Double = 0.0
        var clockwiseCPLayer: Bool = true {
            didSet {
                if clockwiseCPLayer != oldValue {
                    invalidateGradientCacheCPLayer()
                }
            }
        }
        var roundedCornersCPLayer: Bool = true
        var lerpColorModeCPLayer: Bool = false
        var gradientRotateSpeedCPLayer: CGFloat = 0.0 {
            didSet { invalidateGradientCacheCPLayer() }
        }
        var glowAmountCPLayer: CGFloat = 0.0
        var glowModeCPLayer: CircularProgressGlowMode = .forward
        var progressThicknessCPLayer: CGFloat = 0.5
        var trackThicknessCPLayer: CGFloat = 0.5
        var trackColorCPLayer: UIColor = .black
        var progressInsideFillColorCPLayer: UIColor = .clear
        var colorsArrayCPLayer: [UIColor] = [] {
            didSet { invalidateGradientCacheCPLayer() }
        }
        private var gradientCacheCPLayer: CGGradient?
        private var locationsCacheCPLayer: [CGFloat]?
        
        private enum GlowConstantsCPLayer {
            private static let sizeToGlowRatioCPLayer: CGFloat = 0.00015
            static func glowAmountCPLayer(forAngle angle: Double, glowAmount: CGFloat, glowMode: CircularProgressGlowMode, size: CGFloat) -> CGFloat {
                switch glowMode {
                case .forward:
                    return CGFloat(angle) * size * sizeToGlowRatioCPLayer * glowAmount
                case .reverse:
                    return CGFloat(360.0 - angle) * size * sizeToGlowRatioCPLayer * glowAmount
                case .constant:
                    return 360.0 * size * sizeToGlowRatioCPLayer * glowAmount
                default:
                    return 0
                }
            }
        }
        
        override class func needsDisplay(forKey key: String) -> Bool {
            if key == #keyPath(angleCPView) {
                return true
            }
            return super.needsDisplay(forKey: key)
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
            let progressLayer = layer as! CircularProgressLayer
            radiusCPLayer = progressLayer.radiusCPLayer
            angleCPView = progressLayer.angleCPView
            startAngleCPLayer = progressLayer.startAngleCPLayer
            clockwiseCPLayer = progressLayer.clockwiseCPLayer
            roundedCornersCPLayer = progressLayer.roundedCornersCPLayer
            lerpColorModeCPLayer = progressLayer.lerpColorModeCPLayer
            gradientRotateSpeedCPLayer = progressLayer.gradientRotateSpeedCPLayer
            glowAmountCPLayer = progressLayer.glowAmountCPLayer
            glowModeCPLayer = progressLayer.glowModeCPLayer
            progressThicknessCPLayer = progressLayer.progressThicknessCPLayer
            trackThicknessCPLayer = progressLayer.trackThicknessCPLayer
            trackColorCPLayer = progressLayer.trackColorCPLayer
            colorsArrayCPLayer = progressLayer.colorsArrayCPLayer
            progressInsideFillColorCPLayer = progressLayer.progressInsideFillColorCPLayer
        }
        
        override init() {
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func draw(in ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            
            let size = bounds.size
            let width = size.width
            let height = size.height
            
            let trackLineWidth = radiusCPLayer * trackThicknessCPLayer
            let progressLineWidth = radiusCPLayer * progressThicknessCPLayer
            let arcRadius = max(radiusCPLayer - trackLineWidth / 2.0, radiusCPLayer - progressLineWidth / 2.0)
            ctx.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0),
                       radius: arcRadius,
                       startAngle: 0,
                       endAngle: CGFloat.pi * 2,
                       clockwise: false)
            ctx.setStrokeColor(trackColorCPLayer.cgColor)
            ctx.setFillColor(progressInsideFillColorCPLayer.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let imageCtx = UIGraphicsGetCurrentContext()
            let canonicalAngle = angleCPView.modFloatingPointCPView(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let fromAngle = -startAngleCPLayer.radiansFloatingPointCPView
            let toAngle: Double
            if clockwiseCPLayer {
                toAngle = (-canonicalAngle - startAngleCPLayer).radiansFloatingPointCPView
            } else {
                toAngle = (canonicalAngle - startAngleCPLayer).radiansFloatingPointCPView
            }
            
            imageCtx?.addArc(center: CGPoint(x: width / 2.0, y: height / 2.0),
                             radius: arcRadius,
                             startAngle: CGFloat(fromAngle),
                             endAngle: CGFloat(toAngle),
                             clockwise: clockwiseCPLayer)
            
            let glowValue = GlowConstantsCPLayer.glowAmountCPLayer(forAngle: canonicalAngle, glowAmount: glowAmountCPLayer, glowMode: glowModeCPLayer, size: width)
            if glowValue > 0 {
                imageCtx?.setShadow(offset: .zero, blur: glowValue, color: UIColor.black.cgColor)
            }
            
            let linecap: CGLineCap = roundedCornersCPLayer ? .round : .butt
            imageCtx?.setLineCap(linecap)
            imageCtx?.setLineWidth(progressLineWidth)
            imageCtx?.drawPath(using: .stroke)
            
            let drawMask: CGImage = UIGraphicsGetCurrentContext()!.makeImage()!
            UIGraphicsEndImageContext()
            
            ctx.saveGState()
            ctx.clip(to: bounds, mask: drawMask)
            
            if colorsArrayCPLayer.isEmpty {
                fillRectCPLayer(withContext: ctx, color: .white)
            } else if colorsArrayCPLayer.count == 1 {
                fillRectCPLayer(withContext: ctx, color: colorsArrayCPLayer[0])
            } else if lerpColorModeCPLayer {
                lerpCPLayer(withContext: ctx, colorsArray: colorsArrayCPLayer)
            } else {
                drawGradientCPLayer(withContext: ctx, colorsArray: colorsArrayCPLayer)
            }

            ctx.restoreGState()
            UIGraphicsPopContext()
        }
        
        private func lerpCPLayer(withContext context: CGContext, colorsArray: [UIColor]) {
            let canonicalAngle = angleCPView.modFloatingPointCPView(between: 0.0, and: 360.0, byIncrementing: 360.0)
            let percentage = canonicalAngle / 360.0
            let steps = colorsArray.count - 1
            let step = 1.0 / Double(steps)
            
            for i in 1...steps {
                let di = Double(i)
                if percentage <= di * step || i == steps {
                    let colorT = percentage.inverseLerpCPView(min: (di - 1) * step, max: di * step)
                    let color = colorT.colorLerpCPView(minColor: colorsArray[i - 1], maxColor: colorsArray[i])
                    fillRectCPLayer(withContext: context, color: color)
                    break
                }
            }
        }
        
        private func fillRectCPLayer(withContext context: CGContext, color: UIColor) {
            context.setFillColor(color.cgColor)
            context.fill(bounds)
        }
        
        private func drawGradientCPLayer(withContext context: CGContext, colorsArray: [UIColor]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCacheCPLayer ?? gradientLocationsCPLayer(colorCount: colorsArray.count, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCacheCPLayer {
                gradient = cachedGradient
            } else {
                guard let newGradient = CGGradient(colorSpace: baseSpace, colorComponents: colorsArray.rgbColorCPView.componentsCPView,
                                                   locations: locations, count: colorsArray.count) else { return }
                
                gradientCacheCPLayer = newGradient
                gradient = newGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat.pi
            let rotateSpeed = clockwiseCPLayer == true ? gradientRotateSpeedCPLayer : gradientRotateSpeedCPLayer * -1.0
            let angleInRadians = (rotateSpeed * CGFloat(angleCPView) - 90.0).radiansFloatingPointCPView
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
        }
        
        private func gradientLocationsCPLayer(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            guard colorCount > 0, gradientWidth > 0 else { return [] }

            let progressLineWidth = radiusCPLayer * progressThicknessCPLayer
            let firstPoint = gradientWidth / 2.0 - (radiusCPLayer - progressLineWidth / 2.0)
            let increment = (gradientWidth - (2.0 * firstPoint)) / CGFloat(colorCount - 1)
            
            let locationsArray = (0..<colorCount).map { firstPoint + (CGFloat($0) * increment) }
            let result = locationsArray.map { $0 / gradientWidth }
            locationsCacheCPLayer = result
            return result
        }
        
        private func invalidateGradientCacheCPLayer() {
            gradientCacheCPLayer = nil
            locationsCacheCPLayer = nil
        }
    }
}

private extension Array where Element == UIColor {
    var rgbColorCPView: [UIColor] {
        return map { color in
            guard color.cgColor.numberOfComponents == 2 else {
                return color
            }
            
            let white: CGFloat = color.cgColor.components![0]
            return UIColor(red: white, green: white, blue: white, alpha: 1.0)
        }
    }
    
    var componentsCPView: [CGFloat] {
        return flatMap { $0.cgColor.components ?? [] }
    }
}

private extension Comparable {
    func clampComparableCPView(lowerBound: Self, upperBound: Self) -> Self {
        return min(max(self, lowerBound), upperBound)
    }
}

private extension FloatingPoint {
    var radiansFloatingPointCPView: Self {
        return self * .pi / Self(180)
    }
    
    func modFloatingPointCPView(between left: Self, and right: Self, byIncrementing interval: Self) -> Self {
        assert(interval > 0)
        assert(interval <= right - left)
        assert(right > left)
        
        if self >= left, self <= right {
            return self
        } else if self < left {
            return (self + interval).modFloatingPointCPView(between: left, and: right, byIncrementing: interval)
        } else {
            return (self - interval).modFloatingPointCPView(between: left, and: right, byIncrementing: interval)
        }
    }
}

private extension BinaryFloatingPoint {
    func inverseLerpCPView(min: Self, max: Self) -> Self {
        return (self - min) / (max - min)
    }
    
    func lerpBinaryCPView(min: Self, max: Self) -> Self {
        return (max - min) * self + min
    }
    
    func colorLerpCPView(minColor: UIColor, maxColor: UIColor) -> UIColor {
        let clampedValue = CGFloat(self.clampComparableCPView(lowerBound: 0.0, upperBound: 1.0))
        let zero = CGFloat(0.0)
        
        
        var (r0, g0, b0, a0) = (zero, zero, zero, zero)
        minColor.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        
        var (r1, g1, b1, a1) = (zero, zero, zero, zero)
        maxColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        
        return UIColor(red: clampedValue.lerpBinaryCPView(min: r0, max: r1),
                       green: clampedValue.lerpBinaryCPView(min: g0, max: g1),
                       blue: clampedValue.lerpBinaryCPView(min: b0, max: b1),
                       alpha: clampedValue.lerpBinaryCPView(min: a0, max: a1))
    }
}
