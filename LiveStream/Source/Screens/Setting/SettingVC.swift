//
//  SettingVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class SettingVC: BaseVC {
    
    @IBOutlet weak var navigationView: NavigationBarView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigation()
        self.setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .white
    }
    
    private func setupNavigation() {
        self.navigationView.title = "Setting"
        self.navigationView.didSelected = {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "SettingCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "SettingCollectionViewCell")
        self.collectionView.showsHorizontalScrollIndicator = false
    }
}

extension SettingVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        case 1:
            let url = "https://sites.google.com/view/screenrecorder-arcadelive/support"
            self.openSafari(urlString: url)
        case 2:
            if let url = URL(string: ""), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        case 3:
            if let url = URL(string: ""), !url.absoluteString.isEmpty {
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.present(vc, animated: true)
            }
        case 4:
            let url = "https://sites.google.com/view/screenrecorder-arcadelive/privacy-policy"
            self.openSafari(urlString: url)
        case 5:
            let url = "https://sites.google.com/view/screenrecorder-arcadelive/terms-and-condition"
            self.openSafari(urlString: url)
        default:
            break
        }
    }
}

extension SettingVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SettingType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SettingCollectionViewCell", for: indexPath) as? SettingCollectionViewCell else { return SettingCollectionViewCell() }
        cell.configure(type: SettingType.allCases[indexPath.row])
        return cell
    }
}

extension SettingVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = widthScreen - 32.0
        let height = 60.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 19.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: .zero, left: 16.0, bottom: .zero, right: 16.0)
    }
}
