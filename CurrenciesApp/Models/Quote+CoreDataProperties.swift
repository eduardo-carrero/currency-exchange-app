//
//  Quote+CoreDataProperties.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 27/7/21.
//
//

import Foundation
import CoreData


extension Quote {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Quote> {
        return NSFetchRequest<Quote>(entityName: "Quote")
    }

    @NSManaged public var name: String
    @NSManaged public var usdValue: Double
    @NSManaged public var date: Date
    @NSManaged public var currencyDescription: String

}

extension Quote : Identifiable {

}
