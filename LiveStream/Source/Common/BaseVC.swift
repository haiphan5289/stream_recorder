//
//  BaseVC.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import SafariServices

class BaseVC: UIViewController {
    
    var tapDismiss: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tapDismissKeyBoard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.setGradientBackground()
        self.view.backgroundColor = UIColor(hexString: "#F8F8F8")
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func tapDismissKeyBoard(view: UIView? = nil) {
        guard self.tapDismiss == nil else { return }
        
        self.tapDismiss = UITapGestureRecognizer(target: self, action: #selector(onDimiss(tap:)))
        self.tapDismiss.numberOfTapsRequired = 1
        self.tapDismiss.cancelsTouchesInView = false
        if let view = view {
            view.addGestureRecognizer(tapDismiss)
        } else {
            self.view.addGestureRecognizer(tapDismiss)
        }
        
        self.addListener()
    }
    
    func addListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func kbShow(notification: Notification) {
        isShowKB = true
    }
    
    @objc func kbHide(notification: Notification) {
        isShowKB = false
    }
    
    @objc func onDimiss(tap : UITapGestureRecognizer) {
        if isShowKB { self.view.endEditing(false) }
    }
    
    func openSafari(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let safariVC = SFSafariViewController(url: url)
        self.present(safariVC, animated: true)
    }
    
    func showAlertCustom(title: String, message: String, buttonFirst: String, buttonSecond: String, colorFirst: UIColor, colorSecond: UIColor, completionHandleFirst: @escaping () -> Void = {}, completionHandleSecond : @escaping () -> Void = {}) {
        Alert.shared.show(vc: self, title: title, message: message, buttons: [buttonFirst, buttonSecond], colors: [colorFirst, colorSecond]) {(buttonPressed) -> Void in
            if buttonPressed == buttonFirst {
                completionHandleFirst()
            } else if buttonPressed == buttonSecond {
                completionHandleSecond()
            }
        }
    }
    
    func setGradientBackground() {
        let colorTop =  UIColor(hexString: "#054AFE").cgColor
        let colorBottom = UIColor(hexString: "#2DBAFF").cgColor
                    
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
                
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
}
