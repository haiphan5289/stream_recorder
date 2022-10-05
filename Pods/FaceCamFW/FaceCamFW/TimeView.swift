//
//  TimeView.swift
//  xrecorder
//
//  Created by Huy on 14/03/2021.
//

import UIKit

class TimeView: UIView {
    
    public var timeLabel       = UILabel()
    public var backgroundView  = UIView() {
        willSet(newBackgroundView){
            self.backgroundView.removeFromSuperview()
        }
        didSet {
            self.frame = CGRect(x: 0,
                                y: -backgroundView.frame.height,
                                width: backgroundView.frame.width,
                                height: backgroundView.frame.height)
            
            self.addSubview(backgroundView)
            self.sendSubviewToBack(backgroundView)
        }
    }
    
    public var marginTop: CGFloat       = 5.0
    public var marginBottom: CGFloat    = 5.0
    public var marginLeft: CGFloat      = 5.0
    public var marginRight: CGFloat     = 5.0
    
    private var fontSize: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 25 : 15
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(size: CGSize, position: CGFloat) {
        let frame = CGRect(x: 0,
                           y: position == 0 ? -size.height : position,
                           width: size.width,
                           height: size.height)
        super.init(frame: frame)
        
        // Add Background View
        self.backgroundView.frame = self.bounds
        self.addSubview(self.backgroundView)
        
        // Add time label
        self.timeLabel = UILabel()
        self.timeLabel.font = UIFont.systemFont(ofSize: fontSize)
        self.timeLabel.textAlignment = .center
        self.timeLabel.textColor = UIColor.lightGray
        self.addSubview(self.timeLabel)

    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView.frame = self.bounds
        let timeLabelFrameWidth = self.frame.width - (marginRight + marginLeft)
        let timeLabelFrameHeight = self.frame.height - (marginBottom + marginTop)
        self.timeLabel.frame = CGRect(x: marginLeft,
                                      y: marginTop,
                                      width: timeLabelFrameWidth,
                                      height: timeLabelFrameHeight)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
