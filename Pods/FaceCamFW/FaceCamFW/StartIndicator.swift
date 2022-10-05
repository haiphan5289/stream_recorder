//
//  StartIndicator.swift
//  xrecorder
//
//  Created by Huy on 15/03/2022
//

import UIKit

class StartIndicator: UIView {
    
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        
        let bundle = Bundle(for: StartIndicator.self)
        let image = UIImage(named: "StartIndicator", in: bundle, compatibleWith: nil)
        
        imageView.frame = self.bounds
        imageView.image = image
        imageView.contentMode = UIView.ContentMode.scaleToFill
        self.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
