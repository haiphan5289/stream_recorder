//
//  InappVC.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit
import SwiftyStoreKit

class InappVC: BaseVC {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var restoreLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var lock3View: UIView!
    @IBOutlet weak var titlelock2Label: UILabel!
    @IBOutlet weak var titlelock1Label: UILabel!
    
    private var productList: [ProductModel] = []
    private var inappHelper = IAPHelper()
    private var productSeleted: String = IAPHelper().week
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollection()
        self.addGestureLabel()
        self.setupInapp()
        self.setupUI()
        self.setLockView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setGradientBackground()
        self.inappHelper.getPrice()
    }
    
    private func setLockView() {
        if Cache.shared.showOnboard {
            titlelock1Label.text = "Livestream to any Platform"
            titlelock2Label.text = "Unlock all features"
            lock3View.isHidden = false
        } else {
            titlelock1Label.text = "Unlock livestream RTMP"
            titlelock2Label.text = "No Advertising"
            lock3View.isHidden = true
        }
    }
    
    private func setupCollection() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "InappCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "InappCollectionViewCell")
        self.collectionView.showsHorizontalScrollIndicator = false
    }
    
    private func setupUI() {
        DispatchQueue.main.async {
            if !Cache.shared.premium && Cache.shared.showOnboard {
                self.closeButton.isHidden = true
            } else {
                self.closeButton.isHidden = false
            }
        }
    }
    
    private func addGestureLabel() {
        let gesturePrivacy = UITapGestureRecognizer(target: self, action: #selector(self.didTapPrivacy(tap:)))
        gesturePrivacy.numberOfTapsRequired = 1
        gesturePrivacy.cancelsTouchesInView = false
        self.privacyLabel.addGestureRecognizer(gesturePrivacy)
        self.privacyLabel.isUserInteractionEnabled = true
        
        let gestureRestore = UITapGestureRecognizer(target: self, action: #selector(self.didTapRestore(tap:)))
        gestureRestore.numberOfTapsRequired = 1
        gestureRestore.cancelsTouchesInView = false
        self.restoreLabel.addGestureRecognizer(gestureRestore)
        self.restoreLabel.isUserInteractionEnabled = true
        
        let gestureTerms = UITapGestureRecognizer(target: self, action: #selector(self.didTapTerms(tap:)))
        gestureTerms.numberOfTapsRequired = 1
        gestureTerms.cancelsTouchesInView = false
        self.termsLabel.addGestureRecognizer(gestureTerms)
        self.termsLabel.isUserInteractionEnabled = true
        
    }
    
    private func setupInapp() {
        self.inappHelper.listLocalPrice = { prices in
            for (index, value) in prices.enumerated() {
                switch index {
                case 0:
                    let product = ProductModel(name: "One Week", price: value)
                    self.productList.append(product)
                    break
                case 1:
                    let product = ProductModel(name: "One Month", price: value)
                    self.productList.append(product)
                    break
                case 2:
                    let product = ProductModel(name: "One Year", price: value)
                    self.productList.append(product)
                    break
                default:
                    break
                }
            }
            self.collectionView.reloadData()
            self.collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        }
        self.inappHelper.nothingRestore = {
            Alert.shared.showAlert(title: "Error", message: "Nothing to restore", rootVC: self)
        }
        self.inappHelper.purchaseFailed = { message in
            Alert.shared.showAlert(title: "Error", message: message, rootVC: self)
        }
        self.inappHelper.purchaseSuccess = {
            Cache.shared.premium = true
            Alert.shared.showAlert(title: "Success", message: "Purchase success full", rootVC: self)
            self.setupUI()
        }
        self.inappHelper.restoreSuccess = {
            Cache.shared.premium = true
            Alert.shared.showAlert(title: "Success", message: "Restore success full", rootVC: self)
            self.setupUI()
        }
    }
    
    @objc private func didTapPrivacy(tap: UITapGestureRecognizer) {
        let url = "https://sites.google.com/view/screenrecorder-arcadelive/privacy-policy"
        self.openSafari(urlString: url)
    }
    
    @objc private func didTapRestore(tap: UITapGestureRecognizer) {
        self.inappHelper.restorePurchase()
    }
    
    @objc private func didTapTerms(tap: UITapGestureRecognizer) {
        let url = "https://sites.google.com/view/screenrecorder-arcadelive/terms-and-condition"
        self.openSafari(urlString: url)
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func didTapSubscribe(_ sender: Any) {
        if SwiftyStoreKit.canMakePayments {
            self.inappHelper.purchase(productID: self.productSeleted)
        }
    }
    
}

extension InappVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.productSeleted = self.inappHelper.week
            break
        case 1:
            self.productSeleted = self.inappHelper.month
            break
        case 2:
            self.productSeleted = self.inappHelper.year
            break
        default:
            break
        }
    }
}

extension InappVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InappCollectionViewCell", for: indexPath) as? InappCollectionViewCell else { return InappCollectionViewCell() }
        cell.configure(product: self.productList[indexPath.row])
        return cell
    }
}

extension InappVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = widthScreen - 32.0
        let height = 50.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: .zero, left: 16.0, bottom: .zero, right: 16)
    }
}
