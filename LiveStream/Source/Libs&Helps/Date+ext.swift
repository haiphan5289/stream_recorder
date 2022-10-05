//
//  Date+ext.swift
//  LiveStream
//
//  Created by htv on 17/08/2022.
//

import UIKit

extension Date {
    func dateToString(format: String = "dd-MMM-yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = format
        let stringDate = formatter.string(from: yourDate!)
       return stringDate
    }
}
