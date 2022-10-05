//
//  ProgressView.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import PixelSDK

class ProgressView: UIView, Modal {
    var backgroundView: UIView = UIView()
    var dialogPView: UIView = UIView()
    
    lazy var vProgress: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startAngleCPView = -90
        view.progressThicknessCPView = 0.3
        view.trackThicknessCPView = 0.5
        view.clockwiseCPView = true
        view.roundedCornersCPView = false
        view.glowModeCPView = .forward
        view.glowAmountCPView = 0.9
        view.trackColorCPView = UIColor.black.withAlphaComponent(0.5)
        view.progressColorsCPView = [UIColor(hexString: "d9ecfc"), UIColor(hexString: "a190d4"), UIColor(hexString: "ff758e")]

        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.setMedium(size: 17)
        lbl.textColor = UIColor.black
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        return lbl
    }()
    
    lazy var buttonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 48
        
        return view
    }()
    
    lazy var iconImageView: UIImageView = {
        let imv = UIImageView()
        imv.translatesAutoresizingMaskIntoConstraints = false
        imv.image = #imageLiteral(resourceName: "icStreamFailed")
        
        return imv
    }()
    
    lazy var actionButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Save", attributes: [NSAttributedString.Key.font: UIFont.setMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.white]), for: .normal)
        btn.backgroundColor = UIColor(hexString: "886ddb")
        btn.addTarget(self, action: #selector(didTapActionBtnPView), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var laterButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: [NSAttributedString.Key.font: UIFont.setMedium(size: 17), NSAttributedString.Key.foregroundColor: UIColor.black]), for: .normal)
        btn.backgroundColor = UIColor(hexString: "f3f5f6")
        btn.addTarget(self, action: #selector(didTapCloseBtnPView), for: .touchUpInside)
        btn.cornerRadius = 30
        
        return btn
    }()
    
    lazy var buttonStackView: UIStackView = {
        let stv = UIStackView()
        stv.translatesAutoresizingMaskIntoConstraints = false
        stv.axis = .horizontal
        stv.alignment = .fill
        stv.distribution = .fill
        stv.spacing = 16
        
        return stv
    }()
    
    var callbackPView: ((Bool, Session?) -> Void)?
    weak var currenSessionPView: Session?
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        setupDisplayPView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupDisplayPView() {

        //Background
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        addSubview(backgroundView)
        
        backgroundView.addSubview(dialogPView)
        
        dialogPView.cornerRadius = 48
        dialogPView.backgroundColor = UIColor(hexString: "efedf4")
        dialogPView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dialogPView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            dialogPView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            dialogPView.bottomAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        dialogPView.addSubview(titleLabel)
        dialogPView.addSubview(iconImageView)
        dialogPView.addSubview(vProgress)
        dialogPView.addSubview(buttonView)
        buttonView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(laterButton)
        buttonStackView.addArrangedSubview(actionButton)
        
        NSLayoutConstraint.activate([
            buttonView.heightAnchor.constraint(equalToConstant: 96),
            buttonView.leadingAnchor.constraint(equalTo: dialogPView.leadingAnchor),
            buttonView.trailingAnchor.constraint(equalTo: dialogPView.trailingAnchor),
            buttonView.bottomAnchor.constraint(equalTo: dialogPView.bottomAnchor),
            
            buttonStackView.leadingAnchor.constraint(equalTo: buttonView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonView.trailingAnchor, constant: -16),
            buttonStackView.topAnchor.constraint(equalTo: buttonView.topAnchor, constant: 16),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonView.bottomAnchor, constant: -16),
            
            laterButton.widthAnchor.constraint(equalTo: actionButton.widthAnchor),
            
            titleLabel.bottomAnchor.constraint(equalTo: buttonView.topAnchor, constant: -55),
            titleLabel.centerXAnchor.constraint(equalTo: dialogPView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: dialogPView.leadingAnchor, constant: 52),
            
            vProgress.centerXAnchor.constraint(equalTo: dialogPView.centerXAnchor),
            vProgress.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -20),
            vProgress.widthAnchor.constraint(equalToConstant: 76),
            vProgress.heightAnchor.constraint(equalToConstant: 76),
            vProgress.topAnchor.constraint(equalTo: dialogPView.topAnchor, constant: 74),
                        
            iconImageView.leadingAnchor.constraint(equalTo: vProgress.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: vProgress.trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: vProgress.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: vProgress.bottomAnchor)
        ])
        
        vProgress.isHidden = false
        actionButton.isHidden = true
        iconImageView.isHidden = true
        titleLabel.text = "Progressing"
    }
    
    func configureWithSessionPView(sdkSession session: Session) {
        self.currenSessionPView = session
        if let video = session.video {
            VideoExporter.shared.export(video: video, progress: { progress in
                self.vProgress.progressCPView = progress
                self.titleLabel.text = "Progressing"
            }, completion: { error in
                if let _ = error {
                    self.updateUIFailedPView()
                    return
                }

                self.updateUIDonePView()
            })
        }
    }
    
    func updateUIDonePView() {
        iconImageView.image = #imageLiteral(resourceName: "ic_savedsuccess")
        actionButton.isHidden = false
        vProgress.isHidden = true
        iconImageView.isHidden = false
        titleLabel.text = "Edit progress success. Let's save!"
    }
    
    func updateUIFailedPView() {
        iconImageView.image = #imageLiteral(resourceName: "ic_streamfailed")
        actionButton.isHidden = false
        vProgress.isHidden = true
        iconImageView.isHidden = false
        titleLabel.text = "Edit progress failed. Please try later"
    }
    
    @objc func didTapCloseBtnPView() {
        callbackPView?(false, currenSessionPView)
        dismiss(animated: true)
    }
    
    @objc func didTapActionBtnPView() {
        callbackPView?(true, currenSessionPView)
        dismiss(animated: true)
    }
}
