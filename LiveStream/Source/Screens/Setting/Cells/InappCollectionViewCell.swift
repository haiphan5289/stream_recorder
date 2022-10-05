//
//  InappCollectionViewCell.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit

class InappCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? .clear : .white.withAlphaComponent(0.16)
            self.layer.borderWidth = isSelected ? 2 : 0
            self.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.clear.cgColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white.withAlphaComponent(0.16)
    }
    
    func configure(product: ProductModel) {
        self.nameLabel.text = product.name
        self.priceLabel.text = product.price
    }

}
