//
//  ParameterView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class ParameterView: UIView {
    
    @IBOutlet var parameterView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var parameterLabel: UILabel!
    
    var title: String = "" {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    var parameter: String = "" {
        didSet {
            self.parameterLabel.text = parameter
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ParameterView", owner: self, options: nil)
        self.addSubview(self.parameterView)
        self.parameterView.frame = self.bounds
        self.parameterView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}
