//
//  Quote+CoreDataClass.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 27/7/21.
//
//

import Foundation
import CoreData

@objc(Quote)
public class Quote: NSManagedObject {
    func configure(withName name: String, date: Date, usdValue: Double) {
        self.name = name
        self.date = date
        self.usdValue = usdValue
    }
}
