//
//  File.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit

class Alert: NSObject {
    static var one: () = {
        StaticAlert.instanceAlert = Alert()
    }()
    
    struct StaticAlert {
        static var oneToken: Int = 0
        static var instanceAlert: Alert?
    }
    
    class var shared: Alert {
        _ = Alert.one
        return StaticAlert.instanceAlert!
    }
    
    var completion: ((String) -> Void)!
    var buttons: [String]!
    var colorButtons: [String]!
    var alertC: UIAlertController?
    
    func show(vc: UIViewController, title: String, message: String, buttons: [String], colors: [UIColor], completion: ((String) -> Void)?) {
        alertC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for (index, obj) in buttons.enumerated() {
            let alert = UIAlertAction(title: obj, style: .default) { (action: UIAlertAction) -> Void in
                completion!(action.title!)
            }
            alert.setValue(colors[index], forKey: "titleTextColor")
            alertC?.addAction(alert)
        }
        vc.present(alertC!, animated: true)
    }
    
    func showAlert(title: String, message: String, rootVC: UIViewController? = nil) {
        if let vc = rootVC {
            DispatchQueue.main.async {
                let alertC = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertC.addAction(UIAlertAction(title: "OK", style: .default))
                vc.present(alertC, animated: true)
            }
        }
    }
}
