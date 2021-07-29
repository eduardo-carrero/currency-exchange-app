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

enum AmountField {
    case upper
    case lower
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
    
    var selectCurrencyAction: ((AmountField) -> Void)?

    var upperQuote: Quote?
    var lowerQuote: Quote?
    
    @IBOutlet weak var upperTextField: UITextField!
    @IBOutlet weak var lowerTextField: UITextField!
    @IBOutlet weak var upperNameLabel: UILabel!
    @IBOutlet weak var lowerNameLabel: UILabel!
    @IBOutlet weak var upperDescriptionLabel: UILabel!
    @IBOutlet weak var lowerDescriptionLabel: UILabel!
    @IBOutlet weak var upperImageView: UIImageView!
    @IBOutlet weak var lowerImageView: UIImageView!
    
    @IBAction func upperCurrencyTapped(_ sender: UITapGestureRecognizer) {
        print("\(#function)")
        selectCurrencyAction?(.upper)
    }
    @IBAction func lowerCurrencyTapped(_ sender: UITapGestureRecognizer) {
        print("\(#function)")
        selectCurrencyAction?(.lower)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureKeyboard()
        
        container = NSPersistentContainer(name: "CurrenciesApp")

        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error {
                print("Unresolved error \(error)")
            }
        }
        
        changeCurrency(inField: .upper, toQuote: getUSDQuote())
        changeCurrency(inField: .lower, toQuote: getUSDQuote())
        
        performSelector(inBackground: #selector(fetchDescriptions), with: nil)
        
//        loadSavedData()
    }
    
    func convertAmount(amount: Double, fromQuote: Quote, toQuote: Quote) {
        //TODO
    }
    
    func changeCurrency(inField field: AmountField, toQuote newQuote: Quote) {
        let textField = field == .upper ? upperTextField : lowerTextField
        let oldQuote = field == .upper ? upperQuote : lowerQuote
        let multiplier = newQuote.usdValue / (oldQuote?.usdValue ?? 1.0)
        var amount = textField?.text?.doubleWithFormatter(formatter: formatter) ?? 0.0
        amount = amount * multiplier
        textField?.text = formatter.string(from: NSNumber(value: amount))
        if field == .upper {
            upperQuote = newQuote
            upperImageView.image = UIImage(named: newQuote.name.lowercased())
            upperNameLabel.text = newQuote.name
            upperDescriptionLabel.text = newQuote.currencyDescription
        } else {
            lowerQuote = newQuote
            lowerImageView.image = UIImage(named: newQuote.name.lowercased())
            lowerNameLabel.text = newQuote.name
            lowerDescriptionLabel.text = newQuote.currencyDescription
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let currenciesTvc = segue.destination as? CurrenciesTVC {
            currenciesTvc.fetchedResultsController = fetchedResultsController
            // TODO: title, anything else
        }
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
        quote.configure(withName: "USD", date: Date(), usdValue: 1, description: "United States Dollar")
        saveContext()

        return quote
    }
        
    @objc func fetchDescriptions() {
        guard let url = URL(string: "https://currencylayer.com/site_downloads/cl-currencies-table.txt") else {
            fatalError("\(#function); could not create url.")
        }
        
        if let html = try? String(contentsOf: url) {
            if let doc = try? HTML(html: html, encoding: .utf8) {
                var descriptionsDict: [String: String] = [:]
                for tr in doc.css("tr") {
                    let tds = tr.css("td")
                    if tds.count == 2,
                       let key = tds.first?.text {
                        descriptionsDict[key] = tds[1].text ?? ""
                    }
                }
                print("descriptionsDict: \(descriptionsDict)")
                
                
                
                guard let url2 = URL(string: "\(Self.BASE_URL)\(Self.ENDPOINT)?access_key=\(Self.ACCESS_KEY)") else {
                    fatalError("\(#function); could not create url.")
                }

                if let data = try? String(contentsOf: url2) {
                    // give the data to SwiftyJSON to parse
                    let json = JSON(parseJSON: data)

                    // read the quotes back out
                    let jsonQuoteDict = json["quotes"].dictionaryValue
                    let success = json["success"].boolValue

                    print("Received \(jsonQuoteDict.count) new quotes.")

                    DispatchQueue.main.async { [unowned self] in
                        for (key, value) in jsonQuoteDict {
                            let quote = Quote(context: self.container.viewContext)
                            let name = String(key.suffix(3))
                            self.configure(quote: quote, usingName: name, value: value, timeStamp: json["timestamp"], description: descriptionsDict[name] ?? "")
                        }

                        self.saveContext()
                        //                self.loadSavedData()
                    }
                }
                
            }
        }
    }
    
    func configure(quote: Quote, usingName name: String, value: JSON, timeStamp: JSON, description: String) {
        quote.name = name
        quote.usdValue = value.doubleValue
        quote.date = Date(timeIntervalSince1970: TimeInterval(timeStamp.doubleValue))
        quote.currencyDescription = description
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
//        let writtenField: AmountField = upperTextField.isFirstResponder ? .upper : .lower
        guard let firstResponderTextField = upperTextField.isFirstResponder ? upperTextField : lowerTextField,
              let conversionTextField = upperTextField.isFirstResponder ? lowerTextField : upperTextField else {
            print("Didn't find text field.")
            return
        }
        guard let firstResponderQuote = upperTextField.isFirstResponder ? upperQuote : lowerQuote,
              let conversionQuote = upperTextField.isFirstResponder ? lowerQuote : upperQuote else {
            print("Didn't find quote.")
            return
        }
        view.endEditing(true)
        self.validate(textField: firstResponderTextField, withFormatter: formatter)
        let amount = firstResponderTextField.text?.doubleWithFormatter(formatter: formatter) ?? 0.0
        let newAmount = amount * firstResponderQuote.multiplierTo(quote: conversionQuote)
        
        conversionTextField.text = formatter.string(from: NSNumber(value: newAmount))
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

