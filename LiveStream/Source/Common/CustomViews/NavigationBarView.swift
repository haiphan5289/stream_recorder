//
//  NavigationBarView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class NavigationBarView: UIView {
    @IBOutlet var navigationView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    var didSelected: () -> Void = {}
    var title: String = "" {
        didSet {
            self.titleLabel.text = self.title
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
        Bundle.main.loadNibNamed("NavigationBarView", owner: self, options: nil)
        self.addSubview(self.navigationView)
        self.navigationView.frame = self.bounds
        self.navigationView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        didSelected()
    }
    
}
