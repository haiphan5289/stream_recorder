//
//  UIView+Ext.swift
//  OlaChat
//
//  Created by Rum on 17/11/2020.
//  Copyright © 2021 ABLabs - Tam Duc HD, Ltd. All rights reserved.
//

import UIKit

extension UIProgressView {
    
    @IBInspectable override var cornerRadius: CGFloat {
        get {
            self.cornerRadius
        }
        
        set {
            self.layer.cornerRadius = newValue
            self.clipsToBounds = true
            self.layer.sublayers![1].cornerRadius = newValue
            self.subviews[1].clipsToBounds = true
        }
    }
}

@available(iOS 9.0, *)
extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
      get {
        return layer.shadowRadius
      }
      set {
        layer.shadowRadius = newValue
      }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    var size: CGSize {
        get {
            return self.frame.size
        }
        set {
            self.width = newValue.width
            self.height = newValue.height
        }
    }
    
    var width: CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            self.frame.size.width = newValue
        }
    }
    
    var height: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            self.frame.size.height = newValue
        }
    }
    
    public func fillSuperview() {
        guard let superview = self.superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        
        let constraints: [NSLayoutConstraint] = [
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    class func fromNib(named: String? = nil) -> Self {
            let name = named ?? "\(Self.self)"
            guard
                let nib = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
                else { fatalError("missing expected nib named: \(name)") }
            guard
                let view = nib.first as? Self
                else { fatalError("view of type \(Self.self) not found in \(nib)") }
            return view
        }
    
    public var safeAreaFrame: CGRect {
        if #available(iOS 11, *) {
            return safeAreaLayoutGuide.layoutFrame
        }
        return bounds
    }
    
    func allSubViewsOf<T: UIView>(type: T.Type) -> [T]{
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T{
                all.append(aView)
            }
            guard view.subviews.count>0 else { return }
            view.subviews.forEach{ getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }
    
//    func addShadowDecorate(radius: CGFloat = 8,
//                           maskCorner: CACornerMask,
//                        shadowColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3),
//                        shadowOffset: CGSize = CGSize(width: 0, height: 1.0),
//                        shadowRadius: CGFloat = 3,
//                        shadowOpacity: Float = 1) {
//        self.layer.cornerRadius = radius
//        self.layer.maskedCorners = maskCorner
//        self.clipsToBounds = true
//        self.layer.masksToBounds = false
//        self.layer.shadowRadius = shadowRadius
//        self.layer.shadowOpacity = shadowOpacity
//        self.layer.shadowOffset = shadowOffset
//        self.layer.shadowColor = shadowColor.cgColor
//    }
    
    func addGradientLayerInForeground(frame: CGRect, colors: [UIColor]) {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = colors.map { $0.cgColor }
        self.layer.addSublayer(gradient)
   }

    func addGradientLayerInBackground(frame: CGRect, colors: [UIColor]) {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = colors.map { $0.cgColor }
        self.layer.insertSublayer(gradient, at: 0)
   }
    
    func asImage() -> UIImage {
       if #available(iOS 10.0, *) {
           let renderer = UIGraphicsImageRenderer(bounds: bounds)
           return renderer.image { rendererContext in
               layer.render(in: rendererContext.cgContext)
           }
       } else {
           UIGraphicsBeginImageContext(self.frame.size)
           self.layer.render(in:UIGraphicsGetCurrentContext()!)
           let image = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           return UIImage(cgImage: image!.cgImage!)
       }
    }
    
    func animShow(){
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn],
                       animations: {
                        self.alpha = 1
                        self.transform = .identity
        }, completion: nil)
        self.isHidden = false
    }
    
    func animHide(completion: @escaping () -> Void){
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut],
                       animations: {
                        self.alpha = 0
                        self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)

        },  completion: {(_ completed: Bool) -> Void in
            self.isHidden = true
            completion()
        })
    }
    
    func getSnapshotImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return snapshotImage
    }
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func addDashedBorder() {
        let color = UIColor.black.withAlphaComponent(0.14).cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [3,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: self.frame.height / 2).cgPath
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func cut(by view: UIView, margin: CGFloat) {
        let p: CGMutablePath = CGMutablePath()
        self.clipsToBounds = true
        p.addRect(self.bounds)
        if let frame = superview?.convert(view.frame, to: self) {
            let cutRect = CGRect(x: frame.minX - margin / 2, y: frame.minY - margin / 2, width: frame.width + margin, height: frame.height + margin)
            p.addRoundedRect(in: cutRect, cornerWidth: cutRect.width > cutRect.height ? cutRect.height / 2 : cutRect.width / 2, cornerHeight: cutRect.height / 2)
        } else {
            let frame = self.convert(view.frame, to: self.superview)
            let cutRect = CGRect(x: frame.minX - margin / 2, y: frame.minY - margin / 2, width: frame.width + margin, height: frame.height + margin)
            p.addRoundedRect(in: cutRect, cornerWidth: cutRect.width > cutRect.height ? cutRect.height / 2 : cutRect.width / 2, cornerHeight: cutRect.height / 2)
        }

        let s = CAShapeLayer()
        s.path = p
        s.fillRule = CAShapeLayerFillRule.evenOdd

        self.layer.mask = s
    }
    
    func uncut() {
        let p: CGMutablePath = CGMutablePath()
        self.clipsToBounds = true
        p.addRect(self.bounds)
        let s = CAShapeLayer()
        s.path = p
        s.fillRule = CAShapeLayerFillRule.evenOdd

        self.layer.mask = s
    }
    
    func fadeIn(completion: (() -> Void)? = nil) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1
        }) { (_) in
            completion?()
        }
    }
    
    func fadeOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { (_) in
            self.isHidden = true
            completion?()
        }
    }
    
    func scaleIn(completion: (() -> Void)? = nil) {
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
            self.transform = .identity
            self.alpha = 1
        } completion: { (_) in
            completion?()
        }
    }
    
    func scaleOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            self.alpha = 0
        }) { (_) in
            self.isHidden = true
            completion?()
        }
    }
    
    func shakeAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func pulsate() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 0.95
        pulse.toValue = 1
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        layer.add(pulse, forKey: nil)
    }
    
    func removeConstraints() { removeConstraints(constraints) }
    func deactivateAllConstraints() { NSLayoutConstraint.deactivate(getAllConstraints()) }
    func getAllSubviews() -> [UIView] { return UIView.getAllSubviews(view: self) }

    func getAllConstraints() -> [NSLayoutConstraint] {
        var subviewsConstraints = getAllSubviews().flatMap { $0.constraints }
        if let superview = self.superview {
            subviewsConstraints += superview.constraints.compactMap { (constraint) -> NSLayoutConstraint? in
                if let view = constraint.firstItem as? UIView, view == self { return constraint }
                return nil
            }
        }
        return subviewsConstraints + constraints
    }

    class func getAllSubviews(view: UIView) -> [UIView] {
        return view.subviews.flatMap { [$0] + getAllSubviews(view: $0) }
    }
}

@available(iOS 11.0, *)
class CustomView: UIView {
    @IBInspectable var firstColor: UIColor = UIColor.clear {
       didSet {
           updateView()
        }
     }
     @IBInspectable var secondColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    override class var layerClass: AnyClass {
       get {
          return CAGradientLayer.self
       }
    }
    
    @IBInspectable var isHorizontal: Bool = false {
       didSet {
          updateView()
       }
    }
    
    func updateView() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [firstColor, secondColor].map{$0.cgColor}
        if (self.isHorizontal) {
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint (x: 1, y: 0.5)
        } else {
            layer.startPoint = CGPoint(x: 0.5, y: 0)
            layer.endPoint = CGPoint (x: 0.5, y: 0.5)
        }
    }
    
    @IBInspectable var maskCorner: Bool {
        get {
            return layer.maskedCorners == [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        set {
            if newValue {
                layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            }
        }
    }
}

protocol Modal {
    func show(animated: Bool)
    func dismiss(animated: Bool)
    func show(at vc: UIViewController, animated: Bool)
    var backgroundView: UIView { get }
    var dialogView: UIView { get set }
}

extension Modal where Self: UIView {
    
    func show(at vc: UIViewController, animated: Bool) {
        self.backgroundView.alpha = 0
        self.dialogView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        vc.view.addSubview(self)
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 1
                self.dialogView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        } else {
            self.backgroundView.alpha = 1
        }
    }
    
    func dismiss(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.dialogView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.backgroundView.alpha = 0
            }, completion: { (completed) in
                self.removeFromSuperview()
            })
        } else {
            self.removeFromSuperview()
        }
    }
    
    func showOnNewWindow() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindow.Level.alert + 1  // Swift 3-4: UIWindowLevelAlert + 1
        win.makeKeyAndVisible()
        self.backgroundView.alpha = 0
        self.dialogView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        win.rootViewController?.view.addSubview(self)
        UIView.animate(withDuration: 0.33, animations: {
            self.backgroundView.alpha = 1
            self.dialogView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}

extension UITableView {
    func fadeEdges(with modifier: CGFloat) {
        let visibleCells = self.visibleCells

        guard !visibleCells.isEmpty else { return }
        guard let topCell = visibleCells.first else { return }
        guard let bottomCell = visibleCells.last else { return }

        visibleCells.forEach {
            $0.contentView.alpha = 1
        }

        let cellHeight = topCell.frame.height - 1
        let tableViewTopPosition = self.frame.origin.y
        let tableViewBottomPosition = self.frame.maxY

        guard let topCellIndexpath = self.indexPath(for: topCell) else { return }
        let topCellPositionInTableView = self.rectForRow(at:topCellIndexpath)

        guard let bottomCellIndexpath = self.indexPath(for: bottomCell) else { return }
        let bottomCellPositionInTableView = self.rectForRow(at: bottomCellIndexpath)

        let topCellPosition = self.convert(topCellPositionInTableView, to: self.superview).origin.y
        let bottomCellPosition = self.convert(bottomCellPositionInTableView, to: self.superview).origin.y + cellHeight
        let topCellOpacity = (1.0 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier)
        let bottomCellOpacity = (1.0 - ((bottomCellPosition - tableViewBottomPosition) / cellHeight) * modifier)

        topCell.contentView.alpha = topCellOpacity
        bottomCell.contentView.alpha = bottomCellOpacity
    }
}
