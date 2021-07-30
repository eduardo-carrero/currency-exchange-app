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
    @objc func nameFirstCharacter() -> String {
        let startIndex = name.startIndex
        let first = name[...startIndex]
        return String(first)
    }
    
    func configure(withName name: String, usdValue: Double, description: String, date: Date) {
        self.name = name
        self.usdValue = usdValue
        self.currencyDescription = description
        self.date = date
    }
    
    func multiplierTo(quote: Quote) -> Double {
        return quote.usdValue / usdValue
    }
}
