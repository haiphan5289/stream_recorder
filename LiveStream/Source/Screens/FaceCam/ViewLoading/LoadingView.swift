//
//  LoadingView.swift
//  LiveStream
//
//  Created by haiphan on 05/10/2022.
//

import UIKit
//import NVActivityIndicatorView

class LoadingView: UIView {
    
    @IBOutlet weak var containerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
public protocol LoadXibProtocol {}
public extension LoadXibProtocol where Self: UIView {
    static func loadXib() -> Self {
        let bundle = Bundle(for: self)
        let name = "\(self)"
        guard let view = UINib(nibName: name, bundle: bundle).instantiate(withOwner: nil, options: nil).first as? Self else {
            fatalError("error xib \(name)")
        }
        return view
    }
}
extension UIView: LoadXibProtocol {}
