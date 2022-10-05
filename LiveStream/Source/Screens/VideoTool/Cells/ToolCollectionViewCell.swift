//
//  ToolCollectionViewCell.swift
//  LiveStream
//
//  Created by htv on 19/08/2022.
//

import UIKit

class ToolCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(type: VideoToolType) {
        self.iconImageView.image = type.icon
    }
}
