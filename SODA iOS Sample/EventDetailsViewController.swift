//
//  EventDetailsViewController.swift
//  soda-swift
//
//  Created by Hal Mueller on 6/2/17.
//  Copyright © 2017 Socrata. All rights reserved.
//

import UIKit

class EventDetailsViewController: UITableViewController {

    var eventDictionary: [String : Any]? = nil {
        didSet {
            if let item = eventDictionary {
                let sortedArray = item.sorted{ $0.0 < $1.0 }
                print(sortedArray)
                sortedItems = sortedArray
            }
        }
    }
    var sortedItems: [(key: String, value: Any)]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sortedItems = sortedItems {
            return sortedItems.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventDetailCell", for: indexPath)
        let detailItem = sortedItems?[indexPath.row]
        cell.textLabel?.text = detailItem?.key
        if let value = detailItem?.value {
            cell.detailTextLabel?.text = "\(value)"
        }
        return cell
    }

}
