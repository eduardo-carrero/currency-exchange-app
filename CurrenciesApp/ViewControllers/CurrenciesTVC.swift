//
//  CurrenciesTVC.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 28/7/21.
//

import UIKit
import CoreData

class CurrenciesTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
//    var quote: Quote!
    var quotePredicate: NSPredicate?
    var fetchedResultsController: NSFetchedResultsController<Quote>!
    
    var currencySelectedAction: ((Quote) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "CurrencyCell", bundle: nil), forCellReuseIdentifier: "Quote")
        
        loadSavedData()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        print("sectionInfo.numberOfObjects: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Quote", for: indexPath) as! CurrencyCell
        let quote = fetchedResultsController.object(at: indexPath)
        cell.configure(quote: quote)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let quote = fetchedResultsController.object(at: indexPath)
        currencySelectedAction?(quote)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let name = fetchedResultsController.sections?[section].name {
            return name
        }
        return ""
    }
    
    func loadSavedData() {
        if fetchedResultsController == nil {
            let request = Quote.createFetchRequest()
            let sort = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20

            let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: "nameFirstCharacter", cacheName: nil)
            fetchedResultsController.delegate = self
        }
        
        fetchedResultsController.fetchRequest.predicate = quotePredicate

        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("Fetch failed")
        }
    }
}
