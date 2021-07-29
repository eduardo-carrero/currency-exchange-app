//
//  String+Utils.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 29/7/21.
//

import Foundation


extension String {
    func doubleWithFormatter(formatter: NumberFormatter) -> Double? {
        var textAux = self.replacingOccurrences(of: formatter.locale.groupingSeparator ?? "", with: "")
        textAux = textAux.replacingOccurrences(of: formatter.locale.decimalSeparator ?? "", with: ".")
        return Double(textAux)
    }
}
