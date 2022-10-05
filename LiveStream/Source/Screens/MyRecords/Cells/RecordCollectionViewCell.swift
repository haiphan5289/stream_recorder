//
//  RecordCollectionViewCell.swift
//  LiveStream
//
//  Created by htv on 15/08/2022.
//

import UIKit
import AVKit
import Photos

class RecordCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var recorderImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.checkImageView.image = isSelected ? UIImage(named: "ic_check") : UIImage(named: "ic_uncheck")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(isEdit: Bool, data: VideoModel) {
        self.durationLabel.text = Int(data.duration).durationToString()
        self.dateLabel.text = data.createAt.dateToString()
        guard let thumb = data.thumb else { return }
        self.recorderImageView.image = UIImage(cgImage: thumb)
        self.checkImageView.isHidden = !isEdit
    }

}
