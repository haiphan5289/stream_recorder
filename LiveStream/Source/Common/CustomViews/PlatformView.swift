//
//  PlatformView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class PlatformView: UIView {
    
    @IBOutlet var platformView: UIView!
    @IBOutlet weak var platformImageView: UIImageView!
    
    var platform: PlatformType = .Facebook {
        didSet {
            self.platformImageView.image = platform.image
        }
    }
    
    var didSelected: () -> Void = {}
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PlatformView", owner: self, options: nil)
        self.addSubview(self.platformView)
        self.platformView.frame = self.bounds
        self.platformView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addGesture()
        self.isUserInteractionEnabled = true
    }
    
    private func addGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didSelected(_:)))
        gesture.numberOfTapsRequired = 1
        gesture.cancelsTouchesInView = false
        self.addGestureRecognizer(gesture)
    }
    
    @objc private func didSelected(_ tap: UITapGestureRecognizer) {
        self.didSelected()
    }
}
