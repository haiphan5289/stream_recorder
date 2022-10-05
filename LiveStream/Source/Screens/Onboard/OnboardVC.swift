//
//  OnboardVC.swift
//  LiveStream
//
//  Created by htv on 23/08/2022.
//

import UIKit

class OnboardVC: BaseVC {
    
    @IBOutlet weak var onboarImg: UIImageView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var pageControl: PageControl!
    @IBOutlet weak var nextGButton: GardienButton!
    
    var currentPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDisplayButton()
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.setBackground()
        super.viewWillAppear(animated)
    }
    
    func setupDisplayButton() {
        nextGButton.firstColor = UIColor(hexString: "FF8500")
        nextGButton.secondColor = UIColor(hexString: "FF5300")
        nextGButton.isHorizontal = true
    }
    
    func setBackground() {
        let colorTop =  UIColor(hexString: "FFFFFF").cgColor
        let colorBottom = UIColor(hexString: "FFFFFF").cgColor
                    
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
                
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
    
    func setupView() {
        self.pageControl.currentPage = 6
        switch currentPage {
        case 0:
            self.onboarImg.image = UIImage(named: "img_1")
            self.buttonView.isHidden = true
            self.startButton.isHidden = false
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        case 1:
            self.onboarImg.image = UIImage(named: "img_2")
            self.buttonView.isHidden = false
            self.startButton.isHidden = true
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        case 2:
            self.onboarImg.image = UIImage(named: "img_3")
            self.buttonView.isHidden = false
            self.startButton.isHidden = true
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        case 3:
            self.onboarImg.image = UIImage(named: "img_4")
            self.buttonView.isHidden = false
            self.startButton.isHidden = true
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        case 4:
            self.onboarImg.image = UIImage(named: "img_5")
            self.buttonView.isHidden = false
            self.startButton.isHidden = true
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        case 5:
            self.onboarImg.image = UIImage(named: "img_6")
            self.buttonView.isHidden = false
            self.startButton.isHidden = true
            self.pageControl.currentPage = currentPage
            self.pageControl.update()
        default:
            break
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        let vc = initVC("OnboardVC") as! OnboardVC
        vc.currentPage = self.currentPage - 1
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func startAction(_ sender: Any) {
        let vc = initVC("OnboardVC") as! OnboardVC
        vc.currentPage = self.currentPage + 1
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        if currentPage < 5 {
            let vc = initVC("OnboardVC") as! OnboardVC
            vc.currentPage = self.currentPage + 1
            self.navigationController?.pushViewController(vc, animated: false)
        } else {
            if Cache.shared.showInappHome {
                let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true)
            } else {
                Application.shared.gotoTabbar()
            }
        }
    }
    
}
