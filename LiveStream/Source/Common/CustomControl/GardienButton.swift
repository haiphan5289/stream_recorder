//
//  GardienButton.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class GardienButton: UIButton {
    @IBInspectable var firstColor: UIColor = .clear {
        didSet {
            updateButtonView()
        }
    }
    
    @IBInspectable var secondColor: UIColor = .clear {
        didSet {
            updateButtonView()
        }
    }
    
    override class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
    
    @IBInspectable var isHorizontal: Bool = false {
        didSet {
            updateButtonView()
        }
    }
    
    func updateButtonView() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [firstColor, secondColor].map({$0.cgColor})
        if self.isHorizontal {
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        } else {
            layer.startPoint = CGPoint(x: 0.5, y: 0)
            layer.endPoint = CGPoint(x: 0.5, y: 1)
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
