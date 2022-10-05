//
//  ImagePicker.swift
//  LiveStream
//
//  Created by htv on 03/10/2022.
//

import UIKit

public protocol PickerImageDelegate: AnyObject {
    func didSelectImage(image: UIImage?)
    func didSelectVideo(url: URL)
}

open class PickerImage: NSObject, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    private let pickerVC: UIImagePickerController
    private weak var presentVC: UIViewController?
    private weak var delegate: PickerImageDelegate?
    
    public init(presentVC: UIViewController, delegate: PickerImageDelegate) {
        self.pickerVC = UIImagePickerController()
        super.init()
        self.presentVC = presentVC
        self.delegate = delegate
        self.pickerVC.delegate = self
        self.pickerVC.allowsEditing = false
        self.pickerVC.mediaTypes = ["public.image"]
    }
    
    public func showCamera() {
        self.pickerVC.sourceType = .camera
        self.pickerVC.allowsEditing = false
        self.presentVC?.present(self.pickerVC, animated: true)
    }
    
    public func showLibary(type: [String]) {
        self.pickerVC.sourceType = .photoLibrary
        self.pickerVC.mediaTypes = type
        self.presentVC?.present(self.pickerVC, animated: true)
    }
    
    private func actionPicker(type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        return UIAlertAction(title: title, style: .default) { [unowned self]  _ in
            self.pickerVC.sourceType = type
            self.presentVC?.present(self.pickerVC, animated: true)
        }
    }
    
    public func presentAlert(sourceView: UIView) {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let actionCamera = self.actionPicker(type: .camera, title: "Take photo"),
           let actionRoll = self.actionPicker(type: .savedPhotosAlbum, title: "Camera Roll"),
           let actionPhoto = self.actionPicker(type: .photoLibrary, title: "Photo Library") {
            alertVC.addAction(actionCamera)
            alertVC.addAction(actionRoll)
            alertVC.addAction(actionPhoto)
        }
        
        alertVC.popoverPresentationController?.sourceView = sourceView
        alertVC.popoverPresentationController?.sourceRect = sourceView.bounds
        alertVC.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        
        self.presentVC?.present(alertVC, animated: true)
    }
    
    private func pickerC(controller: UIImagePickerController, image: UIImage?) {
        controller.dismiss(animated: true)
        self.delegate?.didSelectImage(image: image)
    }
    
    private func pickerC(controller: UIImagePickerController, videoUrl: URL) {
        controller.dismiss(animated: true)
        self.delegate?.didSelectVideo(url: videoUrl)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            self.pickerC(controller: picker, videoUrl: url)
        } else if let image = info[.editedImage] as? UIImage {
            self.pickerC(controller: picker, image: image)
        } else if let image = info[.originalImage] as? UIImage {
            self.pickerC(controller: picker, image: image)
        } else {
            self.pickerC(controller: picker, image: nil)
        }
    }
    
    
}
