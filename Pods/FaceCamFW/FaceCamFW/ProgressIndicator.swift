//
//  ProgressIndicator.swift
//  xrecorder
//
//  Created by Huy on 15/03/2022
//

import UIKit

class ProgressIndicator: UIView {
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let bundle = Bundle(for: StartIndicator.self)
        let image = UIImage(named: "ProgressIndicator", in: bundle, compatibleWith: nil)
        imageView.frame = CGRect(x: (self.bounds.width / 2) - 5, y: 0, width: 10, height: self.bounds.height)
        imageView.image = image
        imageView.contentMode = UIView.ContentMode.scaleToFill
        backgroundColor = UIColor.clear
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: (self.bounds.width / 2) - 5, y: 0, width: 10, height: self.bounds.height)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = CGRect(x: -self.frame.size.width / 2,
                           y: 0,
                           width: self.frame.size.width * 2,
                           height: self.frame.size.height)
        if frame.contains(point) {
            return self
        } else {
            return nil
        }
    }
}
