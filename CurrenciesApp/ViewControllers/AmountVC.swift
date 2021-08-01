//
//  ViewController.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 27/7/21.
//

import UIKit
import CoreData
import SwiftyJSON
import Kanna
import JGProgressHUD

class AmountVC: UIViewController {
    
    // essential URL structure is built using constants
    private static let ACCESS_KEY = "6b9f351735d27814f015763945c807f6"
    private static let WRONG_ACCESS_KEY = "6b9f351735d27814f015763945c807f6shawhra" // for testing
    private static let BASE_URL = "http://api.currencylayer.com/"
    private static let ENDPOINT = "live"
    private static let DESCRIPTIONS_URL = "https://currencylayer.com/site_downloads/cl-currencies-table.txt"
    
    private var usdAmount: Double = 0.0
    private lazy var formatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.maximumFractionDigits = 2
        return currencyFormatter
    }()
    
    private var container: NSPersistentContainer!
    
    private var defaultSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    private var hud: JGProgressHUD?
    
    var selectCurrencyAction: ((AmountVC, CurrencyFieldView) -> Void)?
    
    @IBOutlet weak var upperCurrencyField: CurrencyFieldView!
    @IBOutlet weak var lowerCurrencyField: CurrencyFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        upperCurrencyField.selectCurrencyAction = { [weak self] field in
            guard let self = self else { return }
            self.selectCurrencyAction?(self, field)
        }
        lowerCurrencyField.selectCurrencyAction = { [weak self] field in
            guard let self = self else { return }
            self.selectCurrencyAction?(self, field)
        }
        
        configureKeyboard()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetchCurrencies))
        
        container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error {
                print("Unresolved error \(error)")
            }
        }
        
        fetchCurrencies()
    }
    
    func changeCurrency(inField field: CurrencyFieldView, withQuote newQuote: Quote) {
        field.configure(withQuote: newQuote)
        fillTextFieldWithUsdAmount(field: field, usdAmount: usdAmount)
    }
    
    @objc private func doneButtonAction() {
        let firstResponderField = upperCurrencyField.textField.isFirstResponder ? upperCurrencyField! : lowerCurrencyField!
        view.endEditing(true)
        usdAmount = usdAmountFrom(field: firstResponderField, withFormatter: formatter)
        fillTextFieldsWithUsdAmount(usdAmount: usdAmount)
    }
    
    private func usdAmountFrom(field: CurrencyFieldView, withFormatter formatter: NumberFormatter) -> Double {
        if let amount = field.textField.text?.doubleWithFormatter(formatter: formatter),
           let usdValue = field.quote?.usdValue {
            return amount / usdValue
        }
        return 0.0
    }
    
    private func fillTextFieldsWithUsdAmount(usdAmount: Double) {
        fillTextFieldWithUsdAmount(field: upperCurrencyField, usdAmount: usdAmount)
        fillTextFieldWithUsdAmount(field: lowerCurrencyField, usdAmount: usdAmount)
    }
    
    private func fillTextFieldWithUsdAmount(field: CurrencyFieldView, usdAmount: Double) {
        guard let quote = field.quote else {
            print("Didn't find quote in currency field.")
            field.textField.text = formatter.string(from: 0)
            return
        }
        let convertedAmount = quote.usdValue * usdAmount
        field.textField.text = formatter.string(from: NSNumber(value: convertedAmount))
    }
}

extension AmountVC {
    @objc private func fetchCurrencies() {
        DispatchQueue.main.async {
            self.startProgressHUD()
            DispatchQueue.global().async {
                guard let descUrl = URL(string: Self.DESCRIPTIONS_URL),
                      let quotesUrl = URL(string: "\(Self.BASE_URL)\(Self.ENDPOINT)?access_key=\(Self.ACCESS_KEY)") else {
                    fatalError("\(#function); could not create url.")
                }
                self.defaultSession.get(descUrl, quotesUrl) { descResult, quotesResult in
                    
                    var errorMsg = ""
                    if case let .error(error, _, _) = descResult {
                        errorMsg = errorMsg + "Error fetching descriptions: \(error.localizedDescription)"
                    }
                    if case let .error(error, _, _) = quotesResult {
                        errorMsg = errorMsg.isEmpty ? errorMsg : errorMsg + "\n\n"
                        errorMsg = errorMsg + "Error fetching quotes: \(error.localizedDescription)"
                    }
                    guard errorMsg.isEmpty else {
                        self.finishDataFetchWithError(errorMsg: errorMsg)
                        return
                    }
                    guard case let (descHtml?, quotesStr?) = (descResult.string, quotesResult.string) else {
                        self.finishDataFetchWithError(errorMsg: "Error getting response")
                        return
                    }
                    guard let doc = try? HTML(html: descHtml, encoding: .utf8) else {
                        self.finishDataFetchWithError(errorMsg: "Error parsing descriptions response.")
                        return
                    }
                    var descriptionsDict: [String: String] = [:]
                    for tr in doc.css("tr") {
                        let tds = tr.css("td")
                        if tds.count == 2,
                           let key = tds.first?.text {
                            descriptionsDict[key] = tds[1].text ?? ""
                        }
                    }
                    print("descriptionsDict: \(descriptionsDict)")
                    
                    let json = JSON(parseJSON: quotesStr)
                    let jsonQuoteDict = json["quotes"].dictionaryValue
                    guard json["success"].boolValue else {
                        self.finishDataFetchWithError(errorMsg: "Got error response from server fetching quotes.")
                        return
                    }

                    print("Received \(jsonQuoteDict.count) new quotes.")

                    DispatchQueue.main.async { [unowned self] in
                        for (key, value) in jsonQuoteDict {
                            let quote = Quote(context: self.container.viewContext)
                            let name = String(key.suffix(3))
                            let date = Date(timeIntervalSince1970: TimeInterval(json["timestamp"].doubleValue))
                            quote.configure(withName: name,
                                            usdValue: value.doubleValue,
                                            description: descriptionsDict[name] ?? "",
                                            date: date)
                        }
                        (UIApplication.shared.delegate as! AppDelegate).saveContext()
                        self.finishProgressHUD(success: true)
                    }
                }
            }
        }
    }
    
    private func finishDataFetchWithError(errorMsg: String) {
        print(errorMsg)
        DispatchQueue.main.async {
            self.finishProgressHUD(success: false)
            self.showOKAlert(title: "Error", message: errorMsg)
        }
    }
}

extension AmountVC {
    private func configureKeyboard() {
        upperCurrencyField.textField.keyboardType = .numbersAndPunctuation
        lowerCurrencyField.textField.keyboardType = .numbersAndPunctuation
        addDoneButtonOnKeyboard()
        hideKeyboardWhenTappedAround()
    }
    
    private func addDoneButtonOnKeyboard() {
        upperCurrencyField.textField.inputAccessoryView = createDoneToolbar()
        lowerCurrencyField.textField.inputAccessoryView = createDoneToolbar()
    }
    
    private func createDoneToolbar() -> UIToolbar {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        return doneToolbar
    }
    
    private func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doneButtonAction))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension AmountVC {
    private func startProgressHUD() {
        if hud != nil {
            hud?.dismiss()
        }
        hud = JGProgressHUD(style: .dark)
        hud?.vibrancyEnabled = true
        hud?.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        hud?.textLabel.text = "Fetching data..."
        hud?.detailTextLabel.text = "detalil"
        hud?.show(in: self.view)
    }

    private func finishProgressHUD(success: Bool) {
        hud?.textLabel.text = success ? "Success" : "Error"
        hud?.detailTextLabel.text = nil
        hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud?.dismiss(afterDelay: 0.5)
    }
}
