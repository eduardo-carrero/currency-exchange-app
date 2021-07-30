//
//  UIViewController+Utils.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 28/7/21.
//

import UIKit

extension UIViewController {
    func showOKAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
