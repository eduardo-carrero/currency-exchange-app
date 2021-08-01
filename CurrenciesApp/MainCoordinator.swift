//
//  MainCoordinator.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 29/7/21.
//

import Foundation
import UIKit

class MainCoordinator {
    private(set) var navigationController = UINavigationController()
    private var selectedCurrencyField: CurrencyFieldView?
    
    func start() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let amountVc = storyboard.instantiateInitialViewController() as? AmountVC else {
            fatalError("Missing initial view controller in Main.storyboard.")
        }
        amountVc.selectCurrencyAction = { [weak self] amountVc, field in
            self?.showCurrencyList(fromField: field, viewController: amountVc)
        }
        navigationController.pushViewController(amountVc, animated: false)
    }
    
    private func showCurrencyList(fromField field: CurrencyFieldView, viewController: AmountVC) {
        selectedCurrencyField = field
        let currenciesTvc = CurrenciesTVC()
        currenciesTvc.currencySelectedAction = { [weak self] in
            self?.didSelectCurrency(quote: $0, fromField: field, viewController: viewController)
        }
        navigationController.pushViewController(currenciesTvc, animated: true)
    }
    
    private func didSelectCurrency(quote: Quote, fromField field: CurrencyFieldView, viewController: AmountVC) {
        viewController.changeCurrency(inField: field, withQuote: quote)
        navigationController.popViewController(animated: true)
    }
}
