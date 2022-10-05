//
//  UIFont+ext.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

extension UIFont {
    static let SFProFontBold = "SF Pro Display Bold"
    static let SFProFontHeavy = "SF Pro Display Heavy"
    static let SFProFontRegular = "SF Pro Display Regular"
    static let SFProFontSemibold = "SF Pro Display Semibold"
    static let SFProFontMedium = "SF Pro Display Medium"
    
    static func setRegular(size: CGFloat) -> UIFont {
        let font = UIFont(name: SFProFontRegular, size: size)!
        return font
    }

    static func setBold(size: CGFloat) -> UIFont {
        let font = UIFont(name: SFProFontBold, size: size)!
        return font
    }

    static func setSemiBold(size: CGFloat) -> UIFont {
        let font = UIFont(name: SFProFontSemibold, size: size)!
        return font
    }
    
    static func setMedium(size: CGFloat) -> UIFont {
        let font = UIFont(name: SFProFontMedium, size: size)!
        return font
    }
    
    static func setHeavy(size: CGFloat) -> UIFont {
        let font = UIFont(name: SFProFontHeavy, size: size)!
        return font
    }
}
