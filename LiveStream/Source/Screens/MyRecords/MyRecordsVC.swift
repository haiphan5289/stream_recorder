//
//  MyRecordsVC.swift
//  LiveStream
//
//  Created by htv on 11/08/2022.
//

import UIKit
import AVFoundation

class MyRecordsVC: BaseVC {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sourceSegmented: UISegmentedControl!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editView: UIView!
    
    private var isEdit = false
    private var dataSources: [VideoModel] = []
    private var itemSelected: [IndexPath] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupCollection()
        self.getAllVideo()
        self.setupDisplaySegment()
        self.addGestureEditLabel()
        NotificationCenter.default.addObserver(self, selector: #selector(self.getAllVideo), name: NSNotification.Name("did_record_video"), object: nil)
    }
    
    private func setupUI() {
        self.tabBarController?.tabBar.isHidden = self.isEdit
        self.editView.isHidden = !self.isEdit
        self.titleLabel.text = self.isEdit ? "\(self.itemSelected.count) videos Selected" : "My Recordings"
        self.editLabel.text = self.isEdit ? "Done" : "Edit"
    }
    
    private func addGestureEditLabel() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapEdit(sender:)))
        gesture.numberOfTapsRequired = 1
        gesture.cancelsTouchesInView = false
        self.editLabel.isUserInteractionEnabled = true
        self.editLabel.addGestureRecognizer(gesture)
    }
    
    private func setupCollection() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UINib(nibName: "RecordCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "RecordCollectionViewCell")
        self.collectionView.allowsMultipleSelection = true
    }
    
    private func setupUIEdit() {
        self.itemSelected = self.collectionView.indexPathsForSelectedItems ?? []
        self.titleLabel.text = "\(self.itemSelected.count) videos Selected"
        self.shareButton.isEnabled = self.itemSelected.isEmpty
        self.deleteButton.isEnabled = self.itemSelected.isEmpty
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
    
    private func removeItems() {
        var filesRemove: [URL] = []
        self.itemSelected.forEach { item in
            filesRemove.append(self.dataSources[item.row].url)
        }
        filesRemove.forEach { item in
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: item.path) {
                    try fileManager.removeItem(atPath: item.path)
                } else {
                    print("File does not exist")
                }
            }
            catch let error as NSError {
                print("An error took place: \(error)")
            }
        }
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
        //self.sourceSegmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        //self.sourceSegmented.setTitleTextAttributes([.foregroundColor: UIColor(hexString: "#FF5B39")], for: .selected)
        
    }
    
    @objc private func didTapEdit(sender: UITapGestureRecognizer) {
        self.isEdit = self.isEdit ? false : true
        self.setupUI()
        self.collectionView.reloadData()
    }
    
    @IBAction func didTapSegment(_ sender: UISegmentedControl) {
    }
    
    @IBAction func deleteAction(_ sender: UIButton) {
        if !self.itemSelected.isEmpty {
            Alert.shared.show(vc: self, title: "Confirm Delete", message: "Are you sure you want to delete the \n selected video?", buttons: ["Cancel", "Delete"], colors: [UIColor(hexString: "#007AFF"), UIColor(hexString: "#F31616")]) { title in
                if title == "Delete" {
                    self.removeItems()
                    self.getAllVideo()
                }
            }
        }
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        var urls: [URL] = []
        self.itemSelected.forEach { index in
            urls.append(self.dataSources[index.row].url)
        }
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: [])
        self.present(vc, animated: true)
    }
    
}

extension MyRecordsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isEdit {
            self.setupUIEdit()
        } else {
            let videoPreviewVC = initVC("MyRecordsVC", storyID: "VideoPreviewVC") as! VideoPreviewVC
            videoPreviewVC.video = self.dataSources[indexPath.row]
            videoPreviewVC.modalPresentationStyle = .overFullScreen
            self.present(videoPreviewVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.isEdit {
            self.setupUIEdit()
        }
    }
    
}

extension MyRecordsVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordCollectionViewCell", for: indexPath) as? RecordCollectionViewCell else { return RecordCollectionViewCell() }
        cell.configure(isEdit: self.isEdit, data: self.dataSources[indexPath.row])
        return cell
    }
    
    
}

extension MyRecordsVC: UICollectionViewDelegateFlowLayout {
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
