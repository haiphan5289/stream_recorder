//
//  UIView+ext.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

@IBDesignable
extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: self.layer.borderColor ?? UIColor.clear.cgColor)
        }
        set {
            self.layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var shadowColor: UIColor {
        get {
            return UIColor(cgColor: self.layer.shadowColor ?? UIColor.clear.cgColor)
        }
        set {
            self.layer.shadowColor = newValue.cgColor
        }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return self.layer.shadowOpacity
        }
        set {
            self.layer.shadowOpacity = newValue/100
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return self.layer.shadowRadius
        }
        set {
            self.layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get {
            return self.layer.shadowOffset
        }
        set {
            self.layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable var topCornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.clipsToBounds = true
            self.layer.cornerRadius = newValue
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }
    
    @IBInspectable var bottomCornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.clipsToBounds = true
            self.layer.cornerRadius = newValue
            self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    func fillSuperView() {
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
    
    func addShadow(radius: CGFloat = 8,
                   maskCorner: CACornerMask,
                   shadowColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3),
                   shadowOffset: CGSize = CGSize(width: 0, height: 1.0),
                   shadowRadius: CGFloat = 3,
                   shadowOpacity: Float = 1) {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = maskCorner
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowOffset = shadowOffset
        self.layer.shadowColor = shadowColor.cgColor
    }
}

protocol Modal {
    func show(animated: Bool)
    func dismiss(animated: Bool)
    func show(at vc: UIViewController, animated: Bool)
    var backgroundView: UIView { get }
    var dialogPView: UIView { get set }
}

extension Modal where Self: UIView {
    func dismiss(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.dialogPView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.backgroundView.alpha = 0
            }, completion: { (completed) in
                self.removeFromSuperview()
            })
        } else {
            self.removeFromSuperview()
        }
    }
    
    func show(animated: Bool) {
        self.backgroundView.alpha = 0
        self.dialogPView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        if var topController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.view.addSubview(self)
        } else {
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view.addSubview(self)
        }
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 1
                self.dialogPView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        } else {
            self.backgroundView.alpha = 1
        }
    }
    
    func showOnNewWindowModal() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindow.Level.alert + 1  // Swift 3-4: UIWindowLevelAlert + 1
        win.makeKeyAndVisible()
        self.backgroundView.alpha = 0
        self.dialogPView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        win.rootViewController?.view.addSubview(self)
        UIView.animate(withDuration: 0.33, animations: {
            self.backgroundView.alpha = 1
            self.dialogPView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func show(at vc: UIViewController, animated: Bool) {
        self.backgroundView.alpha = 0
        self.dialogPView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        vc.view.addSubview(self)
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 1
                self.dialogPView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        } else {
            self.backgroundView.alpha = 1
        }
    }
    
}
