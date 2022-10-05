//
//  CustomTextField.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

@IBDesignable
class CustomTextField: UITextField {
    @IBInspectable open var maxLength: Int = 0
    
    var length: Int {
        return (self.text?.trimmingCharacters(in: .whitespacesAndNewlines).count)!
    }
    
    var isEmpty: Bool {
        return self.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false
    }
    
    weak var tfDelegate: CustomTextFieldDelegate?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 13, dy: 15)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 13, dy: 15)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 13, dy: 15)
    }
    
}

protocol CustomTextFieldDelegate: AnyObject {
    func beginEditing(_ tf: UITextField)
    func endEditing(_ tf: UITextField)
    func changeSelection(_ tf: UITextField)
}

extension CustomTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tfDelegate?.beginEditing(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.tfDelegate?.endEditing(textField)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.tfDelegate?.changeSelection(textField)
    }
}
