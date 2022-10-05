//
//  PageControl.swift
//  LiveStream
//
//  Created by htv on 23/08/2022.
//

import UIKit
import CoreMedia

class PageControl: UIPageControl {
    let selectedImg = UIImage(named: "on")!
    let unselectedImg = UIImage(named: "off")!
    
    override var numberOfPages: Int {
        didSet {
            update()
        }
    }
    
    override var currentPage: Int {
        didSet {
            update()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        update()
        clipsToBounds = false
    }
    
    func update() {
        for index in 0..<self.numberOfPages {
            let image = index == currentPage ? selectedImg : unselectedImg
            self.setIndicatorImage(image, forPage: index)
        }
        self.pageIndicatorTintColor = UIColor(hexString: "#DBDBDB")
        self.currentPageIndicatorTintColor = UIColor(hexString: "#FF8500")
    }
}


