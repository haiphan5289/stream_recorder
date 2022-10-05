//
//  TitleView.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class TitleView: UIView {
    
    @IBOutlet var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var title: String = "" {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    var didTapCrown: () -> Void = {}
    var didTapSetting: () -> Void = {}
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("TitleView", owner: self, options: nil)
        self.addSubview(self.titleView)
        self.titleView.frame = self.bounds
        self.titleView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    @IBAction private func didTapCrown(_ sender: Any) {
        self.didTapCrown()
    }
    
    @IBAction private func didTapSetting(_ sender: Any) {
        self.didTapSetting()
    }
}
