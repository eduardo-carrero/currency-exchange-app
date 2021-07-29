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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Quote")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Quote")
        }

        let quote = fetchedResultsController.object(at: indexPath)
        cell?.textLabel?.text = quote.name
        cell?.detailTextLabel?.text = quote.currencyDescription
        
        var image = UIImage(named: quote.name.lowercased())
        if image == nil {
            image = UIImage(named: "ic-no-image")
        }
        cell?.imageView?.image = image
        
        return cell!
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */
    
    //    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    ////        switch type {
    ////        case .delete:
    ////            tableView.deleteRows(at: [indexPath!], with: .automatic)
    ////
    ////            //TODO: see if I should do more cases here.
    ////
    ////        default:
    ////            break
    ////        }
    //    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
