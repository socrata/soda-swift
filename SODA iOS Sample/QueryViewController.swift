//
//  QueryViewController.swift
//  SODASample
//
//  Created by Frank A. Krueger on 8/10/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import UIKit

class QueryViewController: UITableViewController {
    
    // Register for access tokens here: http://dev.socrata.com/register

    let client = SODAClient(domain: "data.seattle.gov", token: "CGxaHQoQlgQSev4zyUh5aR5J3")
    
    let cellId = "EventSummaryCell"
    
    var data: [[String: Any]]! = []
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a pull-to-refresh control
        refreshControl = UIRefreshControl ()
        refreshControl?.addTarget(self, action: #selector(QueryViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        
        // Auto-refresh
        refresh(self)
    }
    
    /// Asynchronous performs the data query then updates the UI
    @objc func refresh (_ sender: Any) {

        // there are about a dozen 1990 records in this particular database that have an incorrectly formatted
        // cad_event_number, so we'll filter them out to get most recent events first.
        let cngQuery = client.query(dataset: "3k2p-39jp").filter("event_clearance_group IS NOT NULL AND cad_event_number < '9000209585'")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        cngQuery.orderDescending("cad_event_number").get { res in
            switch res {
            case .dataset (let data):
                // Update our data
                self.data = data
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                let alertController = UIAlertController(title: "Error Refreshing", message: errorMessage, preferredStyle:.alert)
                self.present(alertController, animated: true, completion: nil)
            }
            
            // Update the UI
            self.refreshControl?.endRefreshing()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.tableView.reloadData()
            self.updateMap(animated: true)
        }
    }
    
    /// Finds the map controller and updates its data
    fileprivate func updateMap(animated: Bool) {
        if let tabs = (self.parent?.parent as? UITabBarController) {
            if let mapNav = tabs.viewControllers![1] as? UINavigationController {
                if let map = mapNav.viewControllers[0] as? MapViewController {
                    map.update(withData: data, animated: animated)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        
        let item = data[indexPath.row]
        
        let name = item["event_clearance_description"]! as! String
        cell?.textLabel?.text = name
        
        let street = item["hundred_block_location"]! as! String
        let city = "Seattle"
        let state = "WA"
        cell?.detailTextLabel?.text = "\(street), \(city), \(state)"
        
        return cell!
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let detailsVC = segue.destination as! EventDetailsViewController
            detailsVC.eventDictionary = data[self.tableView.indexPathForSelectedRow!.row]
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
