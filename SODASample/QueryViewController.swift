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
    
    let cellId = "DetailCell"
    
    var data: [[String: Any]]! = []
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a pull-to-refresh control
        refreshControl = UIRefreshControl ()
        refreshControl?.addTarget(self, action: #selector(QueryViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        
        // Auto-refresh
        refresh(self)
    }
    
    /// Asynchronous performs the data query then updates the UI
    func refresh (_ sender: Any) {

        let cngQuery = client.query(dataset: "3k2p-39jp").filter("within_circle(incident_location, 47.59815, -122.334540, 500) AND event_clearance_group IS NOT NULL")
        
        cngQuery.orderAscending("at_scene_time").get { res in
            switch res {
            case .dataset (let data):
                // Update our data
                self.data = data
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                let alert = UIAlertView(title: "Error Refreshing", message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
            
            // Update the UI
            self.refreshControl?.endRefreshing()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Show the map
        if let tabs = (self.parent?.parent as? UITabBarController) {
            tabs.selectedIndex = 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCell(withIdentifier: cellId) as UITableViewCell!
        
        let item = data[indexPath.row]
        
        let name = item["event_clearance_description"]! as! String
        c?.textLabel?.text = name
        
        let street = item["hundred_block_location"]! as! String
        let city = "Seattle"
        let state = "WA"
        c?.detailTextLabel?.text = "\(street), \(city), \(state)"
        
        return c!
    }
}
