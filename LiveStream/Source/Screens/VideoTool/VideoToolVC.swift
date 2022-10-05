//
//  VideoToolVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit

class VideoToolVC: BaseVC {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleView: TitleView!
    
    var imagePicker: PickerImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollection()
        self.setupTitleView()
        imagePicker = PickerImage(presentVC: self, delegate: self)
    }
    
    private func setupTitleView() {
        self.titleView.title = "Video Tools"
        self.titleView.didTapCrown = {
            let vc = initVC("SettingVC", storyID: "InappVC") as! InappVC
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
        }
        self.titleView.didTapSetting = {
            let vc = initVC("SettingVC", storyID: "SettingVC") as! SettingVC
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func setupCollection() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "ToolCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToolCollectionViewCell")
        self.collectionView.showsHorizontalScrollIndicator = false
    }
    
}

extension VideoToolVC: PickerImageDelegate {
    func didSelectImage(image: UIImage?) {
    }
    
    func didSelectVideo(url: URL) {
        let vc = initVC("FaceCamVC") as! FaceCamVC
        vc.modalPresentationStyle = .overFullScreen
        vc.videoURL = url
        self.present(vc, animated: true)
    }
}

extension VideoToolVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            self.imagePicker.showLibary(type: ["public.movie"])
        case 1:
            let vc = initVC("VideoToolVC", storyID: "RecordsVC") as! RecordsVC
            self.present(vc, animated: true)
        default:
            break
        }
    }
}

extension VideoToolVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VideoToolType.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToolCollectionViewCell", for: indexPath) as? ToolCollectionViewCell else { return ToolCollectionViewCell()}
        cell.configure(type: VideoToolType.allCases[indexPath.row])
        return cell
    }
}

extension VideoToolVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = widthScreen - 32.0
        let height = 150.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: .zero, left: 16, bottom: .zero, right: 16)
    }
}
