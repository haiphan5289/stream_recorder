//
//  SettingCollectionViewCell.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit

class SettingCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(type: SettingType) {
        self.titleLabel.text = type.title
        self.iconImageView.image = type.icon
    }

}
