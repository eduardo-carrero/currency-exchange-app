//
//  ViewController.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 27/7/21.
//

import UIKit
import CoreData
import SwiftyJSON

class AmountVC: UIViewController, NSFetchedResultsControllerDelegate {
    
    // essential URL structure is built using constants
    private static let ACCESS_KEY = "6b9f351735d27814f015763945c807f6"
    private static let WRONG_ACCESS_KEY = "6b9f351735d27814f015763945c807f6shawhra" // for testing
    private static let BASE_URL = "http://api.currencylayer.com/"
    private static let ENDPOINT = "live"
    private static let DESCRIPTIONS_URL = "https://currencylayer.com/site_downloads/cl-currencies-table.txt"
    
    var container: NSPersistentContainer!
    var quotePredicate: NSPredicate?
    var fetchedResultsController: NSFetchedResultsController<Quote>!
    
    private var defaultSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    @IBOutlet weak var upperTextField: UITextField!
    @IBOutlet weak var lowerTextField: UITextField!
    
    @IBAction func upperCurrencyTapped(_ sender: UITapGestureRecognizer) {
        print("\(#function)")
    }
    @IBAction func lowerCurrencyTapped(_ sender: UITapGestureRecognizer) {
        print("\(#function)")
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
        
        performSelector(inBackground: #selector(fetchQuotes), with: nil)
        
        loadSavedData()
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
        predicate.fetchLimit = 1

        if let quotes = try? container.viewContext.fetch(predicate) {
            if quotes.count > 0 {
                return quotes[0]
            }
        }
        let quote = Quote(context: container.viewContext)
        quote.configure(withName: "USD", date: Date(), usdValue: 1)
        saveContext()

        return quote
    }
    
    func loadSavedData() {
        if fetchedResultsController == nil {
            let request = Quote.createFetchRequest()
            let sort = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20

            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
        }
        
//        quotePredicate = NSPredicate(format: "name BEGINSWITH 'E'")
//        quotePredicate = NSPredicate(format: "name == 'EUR'")
        fetchedResultsController.fetchRequest.predicate = quotePredicate

        do {
            try fetchedResultsController.performFetch()
//            tableView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }
    
    @objc func fetchQuotes() {
        guard let url = URL(string: "\(Self.BASE_URL)\(Self.ENDPOINT)?access_key=\(Self.ACCESS_KEY)") else {
            fatalError("\(#function); could not create url.")
        }
        
        if let data = try? String(contentsOf: url) {
            // give the data to SwiftyJSON to parse
            let json = JSON(parseJSON: data)

            // read the quotes back out
            let jsonQuoteDict = json["quotes"].dictionaryValue
            let success = json["success"].boolValue

            print("Received \(jsonQuoteDict.count) new quotes.")

            DispatchQueue.main.async { [unowned self] in
                for (key, value) in jsonQuoteDict {
                    let quote = Quote(context: self.container.viewContext)
                    self.configure(quote: quote, usingKey: key, value: value, timeStamp: json["timestamp"])
                }

                self.saveContext()
                self.loadSavedData()
            }
        }
    }
    
    func configure(quote: Quote, usingKey key: String, value: JSON, timeStamp: JSON) {
        quote.name = String(key.suffix(3))
        quote.usdValue = value.doubleValue
        quote.date = Date(timeIntervalSince1970: TimeInterval(timeStamp.doubleValue))
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
    
    @objc func doneButtonAction() {
        view.endEditing(true)
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .decimal
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.maximumFractionDigits = 2
        
        self.validate(textField: upperTextField, withFormatter: currencyFormatter)
        self.validate(textField: lowerTextField, withFormatter: currencyFormatter)
    }
    
    func validate(textField: UITextField, withFormatter formatter: NumberFormatter) {
        if var text = textField.text {
            text = text.replacingOccurrences(of: formatter.locale.groupingSeparator ?? "", with: "")
            text = text.replacingOccurrences(of: formatter.locale.decimalSeparator ?? "", with: ".")
            if let amount = Double(text) {
                textField.text = formatter.string(from: NSNumber(value: amount))
                return
            }
        }
        textField.text = formatter.string(from: 0)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doneButtonAction))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

