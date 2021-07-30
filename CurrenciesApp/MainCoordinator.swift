//
//  MainCoordinator.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 29/7/21.
//

import Foundation
import UIKit

class MainCoordinator {
    var navigationController = UINavigationController()
    var selectedCurrencyField: CurrencyFieldView?
    
    func start() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let amountVc = storyboard.instantiateInitialViewController() as? AmountVC else {
            fatalError("Missing initial view controller in Main.storyboard.")
        }
        amountVc.selectCurrencyAction = { [weak self] in
            self?.showCurrencyList(fromField: $0)
        }
        navigationController.pushViewController(amountVc, animated: false)
    }
    
    func showCurrencyList(fromField field: CurrencyFieldView) {
        selectedCurrencyField = field
        let currenciesTvc = CurrenciesTVC()
        currenciesTvc.currencySelectedAction = { [weak self] in
            self?.didSelectCurrency(quote: $0)
        }
        navigationController.pushViewController(currenciesTvc, animated: true)
    }
    
    func didSelectCurrency(quote: Quote) {
        print("quote: \(quote)")
        guard let amountVc = navigationController.viewControllers.first as? AmountVC else {
            fatalError("Could not find Amount view controller in navigationController's first position.")
        }
        guard let currencyField = selectedCurrencyField else {
            fatalError("selectedTextField not found.")
        }
        
        amountVc.changeCurrency(inField: currencyField, toQuote: quote)
        navigationController.popViewController(animated: true)
    }
}
