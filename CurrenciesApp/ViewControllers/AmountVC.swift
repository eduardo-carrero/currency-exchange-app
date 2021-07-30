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

extension AmountVC: CurrencyFieldDelegate {
    func currencyFieldSelectCurrencyTapped(currencyField: CurrencyFieldView) {
        selectCurrencyAction?(currencyField)
    }
}

class AmountVC: UIViewController {
    
    // essential URL structure is built using constants
    private static let ACCESS_KEY = "6b9f351735d27814f015763945c807f6"
    private static let WRONG_ACCESS_KEY = "6b9f351735d27814f015763945c807f6shawhra" // for testing
    private static let BASE_URL = "http://api.currencylayer.com/"
    private static let ENDPOINT = "live"
    private static let DESCRIPTIONS_URL = "https://currencylayer.com/site_downloads/cl-currencies-table.txt"
    
//    var usdAmount: Double = 0.0
    lazy var formatter: NumberFormatter = {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.maximumFractionDigits = 2
        return currencyFormatter
    }()
    
    var container: NSPersistentContainer!
    var quotePredicate: NSPredicate?
    var fetchedResultsController: NSFetchedResultsController<Quote>!
    
    private var defaultSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    private var hud: JGProgressHUD?
    
    var selectCurrencyAction: ((CurrencyFieldView) -> Void)?

    var upperQuote: Quote?
    var lowerQuote: Quote?
    
    @IBOutlet weak var upperCurrencyField: CurrencyFieldView!
    @IBOutlet weak var lowerCurrencyField: CurrencyFieldView!
    
    lazy var upperTextField: UITextField = {
        upperCurrencyField.textField
    }()
    lazy var lowerTextField: UITextField = {
        lowerCurrencyField.textField
    }()
    lazy var upperNameLabel: UILabel = {
        upperCurrencyField.nameLabel
    }()
    lazy var lowerNameLabel: UILabel = {
        lowerCurrencyField.nameLabel
    }()
    lazy var upperDescriptionLabel: UILabel = {
        upperCurrencyField.descriptionLabel
    }()
    lazy var lowerDescriptionLabel: UILabel = {
        lowerCurrencyField.descriptionLabel
    }()
    lazy var upperImageView: UIImageView = {
        upperCurrencyField.imageView
    }()
    lazy var lowerImageView: UIImageView = {
        lowerCurrencyField.imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        upperCurrencyField.delegate = self
        lowerCurrencyField.delegate = self
        configureKeyboard()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetchCurrencies))
        
        container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error {
                print("Unresolved error \(error)")
            }
        }
        
//        changeCurrency(inField: .upper, toQuote: getUSDQuote())
//        changeCurrency(inField: .lower, toQuote: getUSDQuote())
        
        fetchCurrencies()
        
//        loadSavedData()
    }
    
    func startProgressHUD() {
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
    
    func finishProgressHUD(success: Bool) {
        hud?.textLabel.text = success ? "Success" : "Error"
        hud?.detailTextLabel.text = nil
        hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud?.dismiss(afterDelay: 0.5)
    }
    
    func convertAmount(amount: Double, fromQuote: Quote, toQuote: Quote) {
        //TODO
    }
    
    func changeCurrency(inField field: CurrencyFieldView, toQuote newQuote: Quote) {
        let textField = field.textField!
        let oldQuote = field.quote
        
        var amount = textField.text?.doubleWithFormatter(formatter: formatter) ?? 0.0
        if oldQuote != nil {
            amount = amount * oldQuote!.multiplierTo(quote: newQuote)
        }
        textField.text = formatter.string(from: NSNumber(value: amount))
        field.configure(withQuote: newQuote)
    }
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("An error occurred while saving: \(error)")
            }
        }
    }
    
    func getUSDQuote() -> Quote {

        let predicate = Quote.createFetchRequest()
//        let sort = NSSortDescriptor(key: "date", ascending: false)
//        newest.sortDescriptors = [sort]
        quotePredicate = NSPredicate(format: "name == 'USD'")
        predicate.predicate = quotePredicate
        predicate.fetchLimit = 1

        if let quotes = try? container.viewContext.fetch(predicate) {
            if quotes.count > 0 {
                return quotes[0]
            }
        }
        let quote = Quote(context: container.viewContext)
        quote.configure(withName: "USD",
                        usdValue: 1,
                        description: "United States Dollar",
                        date: Date())
        (UIApplication.shared.delegate as! AppDelegate).saveContext()

        return quote
    }
    
    @objc func fetchCurrencies() {
        DispatchQueue.main.async {
            self.startProgressHUD()
            DispatchQueue.global().async {
                guard let descUrl = URL(string: "https://currencylayer.com/site_downloads/cl-currencies-table.txt"),
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
                        self.saveContext()
                        self.finishProgressHUD(success: true)
                    }
                }
            }
        }
    }
    
    func finishDataFetchWithError(errorMsg: String) {
        print(errorMsg)
        DispatchQueue.main.async {
            self.finishProgressHUD(success: false)
            self.showOKAlert(title: "Error", message: errorMsg)
        }
    }
}

extension AmountVC {
    func configureKeyboard() {
        upperTextField.keyboardType = .numbersAndPunctuation
        lowerTextField.keyboardType = .numbersAndPunctuation
        addDoneButtonOnKeyboard()
        hideKeyboardWhenTappedAround()
    }
    
    func addDoneButtonOnKeyboard() {
        upperTextField.inputAccessoryView = createDoneToolbar()
        lowerTextField.inputAccessoryView = createDoneToolbar()
    }
    
    func createDoneToolbar() -> UIToolbar {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        return doneToolbar
    }
    
//    @objc func doneButtonAction() {
//        view.endEditing(true)
//        self.validate(textField: upperTextField, withFormatter: formatter)
//        self.validate(textField: lowerTextField, withFormatter: formatter)
//    }
    
    @objc func doneButtonAction() {
        let firstResponderField = upperTextField.isFirstResponder ? upperCurrencyField! : lowerCurrencyField!
        let conversionField = upperTextField.isFirstResponder ? lowerCurrencyField! : upperCurrencyField!
        
        guard let firstResponderQuote = firstResponderField.quote,
              let conversionQuote = conversionField.quote else {
            print("Didn't find quote.")
            view.endEditing(true)
            return
        }
        view.endEditing(true)
        self.validate(textField: firstResponderField.textField, withFormatter: formatter)
        let amount = firstResponderField.textField.text?.doubleWithFormatter(formatter: formatter) ?? 0.0
        let newAmount = amount * firstResponderQuote.multiplierTo(quote: conversionQuote)
        
        conversionField.textField.text = formatter.string(from: NSNumber(value: newAmount))
    }
    
    func validate(textField: UITextField, withFormatter formatter: NumberFormatter) {
        if let amount = textField.text?.doubleWithFormatter(formatter: formatter) {
            textField.text = formatter.string(from: NSNumber(value: amount))
            return
        }
        textField.text = formatter.string(from: 0)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doneButtonAction))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}
