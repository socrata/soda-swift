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

    let client = SODAClient(domain: "data.cityofchicago.org", token: "(Put your access token here)")
    
    let cellId = "DetailCell"
    
    var data: [[String: AnyObject]]! = []
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a pull-to-refresh control
        refreshControl = UIRefreshControl ()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Auto-refresh
        refresh(self)
    }
    
    /// Asynchronous performs the data query then updates the UI
    func refresh (sender: AnyObject!) {

        let cngQuery = client.queryDataset("alternative-fuel-locations").filter("fuel_type_code = 'CNG'")
        
        cngQuery.orderAscending("station_name").get { res in
            switch res {
            case .Dataset (let data):
                // Update our data
                self.data = data
            case .Error (let err):
                let alert = UIAlertView(title: "Error Refreshing", message: err.userInfo.debugDescription, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
            
            // Update the UI
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.updateMap(animated: true)
        }
    }
    
    /// Finds the map controller and updates its data
    private func updateMap(#animated: Bool) {
        if let tabs = (self.parentViewController?.parentViewController as? UITabBarController) {
            if let mapNav = tabs.viewControllers![1] as? UINavigationController {
                if let map = mapNav.viewControllers[0] as? MapViewController {
                    map.updateWithData (data, animated: animated)
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // Show the map
        if let tabs = (self.parentViewController?.parentViewController as? UITabBarController) {
            tabs.selectedIndex = 1
        }
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let c = tableView.dequeueReusableCellWithIdentifier(cellId) as UITableViewCell!
        
        let item = data[indexPath.row]
        
        let name = item["station_name"]! as String
        c.textLabel?.text = name
        
        let street = item["street_address"]! as String
        let city = item["city"]! as String
        let state = item["state"]! as String
        c.detailTextLabel?.text = "\(street), \(city), \(state)"
        
        return c
    }
}
