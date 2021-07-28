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

    @IBAction func lowerCurrencyTapped(_ sender: UITapGestureRecognizer) {
        print("\(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return fetchedResultsController.sections?.count ?? 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sectionInfo = fetchedResultsController.sections![section]
//        print("sectionInfo.numberOfObjects: \(sectionInfo.numberOfObjects)")
//        return sectionInfo.numberOfObjects
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Quote", for: indexPath)
//
//        let quote = fetchedResultsController.object(at: indexPath)
//        cell.textLabel!.text = quote.name
//        cell.detailTextLabel!.text = quote.usdValue.description + " - " + quote.date.description
//
//        return cell
//    }
    
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

