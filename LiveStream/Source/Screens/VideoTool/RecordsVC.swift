//
//  RecordsVC.swift
//  LiveStream
//
//  Created by htv on 19/08/2022.
//

import UIKit
import AVFoundation
import PixelSDK
import Photos

class RecordsVC: BaseVC {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var resourceSegmented: UISegmentedControl!
    
    private var dataSources: [VideoModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollection()
        self.getAllVideo()
        self.setupDisplaySegment()
        NotificationCenter.default.addObserver(self, selector: #selector(self.getAllVideo), name: NSNotification.Name("did_record_video"), object: nil)
    }
    
    private func setupCollection() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "RecordCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "RecordCollectionViewCell")
    }
    
    @objc private func getAllVideo() {
        var videoRecords: [VideoModel] = []
        let urlRecords = FileManager.default.getUrls(in: nil, for: .documentDirectory, skipsHiddenFiles: true) ?? []
        videoRecords = urlRecords.map({ url in
            return self.configureVideo(url: url)
        }).sorted(by: {$0.createAt.compare($1.createAt) == .orderedDescending})
        
        self.dataSources = videoRecords
        self.collectionView.reloadData()
    }
    
    private func configureVideo(url: URL) -> VideoModel {
        let asset = AVAsset(url: url)
        let createDate = asset.creationDate?.value as? Date ?? Date()
        var thumbImage: CGImage?
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let time = CMTimeMake(value: 0, timescale: 1)
            let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            if let image = img {
                thumbImage = image
            }
        }
        return VideoModel(url: url, name: url.lastPathComponent, thumb: thumbImage, duration: asset.duration.seconds, createAt: createDate)
    }
    
    private func setupDisplaySegment() {
        //self.resourceSegmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        //self.resourceSegmented.setTitleTextAttributes([.foregroundColor: UIColor(hexString: "#FF5B39")], for: .selected)
        
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

extension RecordsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let avAsset = AVAsset(url: self.dataSources[indexPath.row].url)
        let _ = Session(assets: [avAsset], sessionReady: { (session, error) in
            guard let session = session,
                let video = session.video else {
                return
            }

            video.primaryFilter = SessionFilterSepulveda()

            let editC = EditController(session: session)
            editC.delegate = self

            let editNC = UINavigationController(rootViewController: editC)
            editNC.modalPresentationStyle = .fullScreen
            self.present(editNC, animated: true, completion: nil)
        })
    }
    
}

extension RecordsVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordCollectionViewCell", for: indexPath) as? RecordCollectionViewCell else { return RecordCollectionViewCell() }
        cell.configure(isEdit: false, data: self.dataSources[indexPath.row])
        return cell
    }
    
    
}

extension RecordsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = 166 * widthScreen/375
        let height = width * 238/166
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 11
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: .zero, bottom: 50, right: .zero)
    }
}

extension RecordsVC: EditControllerDelegate {
    func editController(_ editController: EditController, didFinishEditing session: Session) {
        let progressView = ProgressView()
        progressView.configureWithSessionPView(sdkSession: session)
        progressView.callbackPView = { action, session in
            if action {
                if let videoUrl = session?.video?.exportedVideoURL {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    }) { saved, error in
                        if saved {
                            DispatchQueue.main.async {
                                editController.dismiss(animated: true) {
                                    let alert = UIAlertController(title: "Video saved", message: nil, preferredStyle: .alert)
                                    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alert.addAction(action)
                                    self.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            } else {
                editController.dismiss(animated: true)
            }
        }
        progressView.show(animated: true)
    }
}
