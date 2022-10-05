//
//  IAPHelper.swift
//  LiveStream
//
//  Created by htv on 10/08/2022.
//

import UIKit
import SwiftyStoreKit

class IAPHelper {
    
    let sercetKey = "4ec4ef79a8a94bc4b2c1cfc1dbfe1618"
    let week = "com.premium.week1"
    let month = "com.premium.month1"
    let year = "com.premium.year1"
    
    var listLocalPrice: ([String]) -> Void = {_ in }
    var restoreSuccess: () -> Void = {}
    var nothingRestore: () -> Void = {}
    var purchaseSuccess: () -> Void = {}
    var purchaseFailed: (_ message: String)-> Void = {message in }
    
    func getPrice() {
        SwiftyStoreKit.retrieveProductsInfo([week, month, year]) { [self] result in
            var weekPrice = ""
            var monthPrice = ""
            var yearPrice = ""
            print(result.retrievedProducts.count)
            result.retrievedProducts.forEach { product in
                if let price = product.localizedPrice {
                    switch product.productIdentifier {
                    case self.week:
                        weekPrice = price
                    case self.month:
                        monthPrice = price
                    case self.year:
                        yearPrice = price
                    default:
                        break
                    }
                }
            }
            listLocalPrice([weekPrice, monthPrice, yearPrice])
        }
    }
    
    func restorePurchase() {
        SwiftyStoreKit.restorePurchases(atomically: true) { [self] results in
            if results.restoreFailedPurchases.count > 0 {
                print(results.restoreFailedPurchases)
            } else if results.restoredPurchases.count > 0 {
                restoreSuccess()
            } else {
                nothingRestore()
            }
        }
    }
    
    func purchase(productID: String) {
            SwiftyStoreKit.purchaseProduct(productID, atomically: true) { [self] result in
                switch result {
                case .success:
                    self.purchaseSuccess()
                    
                case .error(let error):
                    switch error.code {
                    case .unknown:
                        purchaseFailed("Unknown error. Please contact support")
                    case .clientInvalid:
                        purchaseFailed("Not allowed to make the payment")
                    case .paymentCancelled:
                        purchaseFailed("Purchase error")
                    case .paymentInvalid:
                        purchaseFailed("The purchase identifier was invalid")
                    case .paymentNotAllowed:
                        purchaseFailed("The device is not allowed to make the payment")
                    case .storeProductNotAvailable:
                        purchaseFailed("The product is not available in the current storefront")
                    case .cloudServicePermissionDenied:
                        purchaseFailed("Access to cloud service information is not allowed")
                    case .cloudServiceNetworkConnectionFailed:
                        purchaseFailed("Could not connect to the network")
                    case .cloudServiceRevoked:
                        purchaseFailed("User has revoked permission to use this cloud service")
                    default: print((error as NSError).localizedDescription)
                        
                    }
                }
            }
        }
}
