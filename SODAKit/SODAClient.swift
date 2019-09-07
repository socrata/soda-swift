//
//  SODAClient.swift
//  SODAKit
//
//  Created by Frank A. Krueger on 8/9/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import Foundation

// Reference: http://dev.socrata.com/consumers/getting-started.html

/// The default number of items to return in SODAClient.queryDataset calls.
public let SODADefaultLimit = 1000

/// The result of an asynchronous SODAClient.queryDataset call. It can either succeed with data or fail with an error.
public enum SODADatasetResult {
    case dataset ([[String: Any]])
    case error (Error)
}

/// The result of an asynchronous SODAClient.getRow call. It can either succeed with data or fail with an error.
public enum SODARowResult {
    case row ([String: Any])
    case error (Error)
}

/// Callback for asynchronous queryDataset methods of SODAClient
public typealias SODADatasetCompletionHandler = (SODADatasetResult) -> Void

/// Callback for asynchronous getRow method of SODAClient
public typealias SODARowCompletionHandler = (SODARowResult) -> Void

/// Consumes data from a Socrata OpenData end point.
public class SODAClient {

    public let domain: String
    public let token: String

    /// Initializes this client to communicate with a SODA endpoint.
    public init(domain: String, token: String) {
        self.domain = domain
        self.token = token
    }

    /// Gets a row using its identifier. See http://dev.socrata.com/docs/row-identifiers.html
    public func get(row: String, inDataset: String, _ completionHandler: @escaping SODARowCompletionHandler) {
        get(dataset: "\(inDataset)/\(row)", withParameters: [:]) { res in
            switch res {
            case .dataset (let rows):
                completionHandler(.row (rows[0]))
            case .error(let err):
                completionHandler(.error (err))
            }
        }
    }

    /// Asynchronously gets a dataset using a simple filter query. See http://dev.socrata.com/docs/filtering.html
    public func get(dataset: String, withFilters: [String: String], limit: Int = SODADefaultLimit, offset: Int = 0, _ completionHandler: @escaping SODADatasetCompletionHandler) {
        var ps = withFilters
        ps["$limit"] = "\(limit)"
        ps["$offset"] = "\(offset)"
        get(dataset: dataset, withParameters: ps, completionHandler)
    }

    /// Low-level access for asynchronously getting a dataset. You should use SODAQueries instead of this. See http://dev.socrata.com/docs/queries.html
    public func get(dataset: String, withParameters: [String: String], _ completionHandler: @escaping SODADatasetCompletionHandler) {
        // Get the URL
        let query = SODAClient.paramsToQueryString (withParameters)
        let path = dataset.hasPrefix("/") ? dataset : ("/resource/" + dataset)
        
        let url = "https://\(self.domain)\(path).json?\(query)"
        let urlToSend = URL(string: url)
        
        // Build the request
        let request = NSMutableURLRequest(url: urlToSend!)
        request.addValue("application/json", forHTTPHeaderField:"Accept")
        request.addValue(self.token, forHTTPHeaderField:"X-App-Token")
        
        // Send it
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, reqError in
        
            // We sync the callback with the main thread to make UI programming easier
            let syncCompletion = { res in OperationQueue.main.addOperation { completionHandler (res) } }
            
            // Give up if there was a net error
            if let error = reqError {
                syncCompletion(.error (error))
                return
            }
            
            // Try to parse the JSON
//            println(NSString (data: data, encoding: NSUTF8StringEncoding))
            
            var jsonError: Error?
            var jsonResult: Any!
            do {
                jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            } catch let error {
                jsonError = error
                jsonResult = nil
            }
            
            if let error = jsonError {
                syncCompletion(.error (error))
                return
            }
            
            // Interpret the JSON
            if let array = jsonResult as? [[String: Any]] {
                syncCompletion(.dataset (array))
            }
            else if let dict = jsonResult as? [String: Any] {
                if let _ = dict["error"], let errorMessage = dict["message"] {
                    syncCompletion(.error (NSError(domain: "SODA", code: 0, userInfo: ["Error": errorMessage])))
                    return
                }
                syncCompletion(.dataset ([dict]))
            }
            else {
                if let error = reqError {
                    syncCompletion(.error (error))
                }
            }
        }
        task.resume()
    }
    
    /// Converts an NSDictionary into a query string.
    fileprivate class func paramsToQueryString (_ params: [String: String]) -> String {
        var s = ""
        var head = ""
        for (key, value) in params {
            let sk = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let sv = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            s += head+sk!+"="+sv!
            head = "&"
        }
        return s
    }
}

/// SODAQuery extension to SODAClient
public extension SODAClient {
    /// Get a query object that can be used to query the client using a fluent syntax.
    func query(dataset: String) -> SODAQuery {
        return SODAQuery (client: self, dataset: dataset)
    }
}

/// Assists in the construction of a SoQL query.
public class SODAQuery
{
    public let client: SODAClient
    public let dataset: String
    
    public let parameters: [String: String]
    
    /// Initializes all the parameters of the query
    public init(client: SODAClient, dataset: String, parameters: [String: String] = [:])
    {
        self.client = client
        self.dataset = dataset
        self.parameters = parameters
    }

    /// Generates SoQL $select parameter. Use the AS operator to modify the output.
    public func select(_ select: String) -> SODAQuery {
        var ps = self.parameters
        ps["$select"] = select
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates SoQL $where parameter. Use comparison operators and AND, OR, NOT, IS NULL, IS NOT NULL. Strings must be single-quoted.
    public func filter(_ filter: String) -> SODAQuery {
        var ps = self.parameters
        ps["$where"] = filter
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates simple filter parameter. Multiple filterColumns are allowed in a single query.
    public func filterColumn(_ column: String, _ value: String) -> SODAQuery {
        var ps = self.parameters
        ps[column] = value
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }

    /// Generates SoQL $q parameter. This uses a multi-column full text search.
    public func fullText(_ fullText: String) -> SODAQuery {
        var ps = self.parameters
        ps["$q"] = fullText
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates SoQL $order ASC parameter.
    public func orderAscending(_ column: String) -> SODAQuery {
        var ps = self.parameters
        ps["$order"] = "\(column) ASC"
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }

    /// Generates SoQL $order DESC parameter.
    public func orderDescending(_ column: String) -> SODAQuery {
        var ps = self.parameters
        ps["$order"] = "\(column) DESC"
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates SoQL $group parameter. Use select() with aggregation functions like MAX and then name the column to group by.
    public func group(_ column: String) -> SODAQuery {
        var ps = self.parameters
        ps["$group"] = column
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates SoQL $limit parameter. The default limit is 1000.
    public func limit(_ limit: Int) -> SODAQuery {
        var ps = self.parameters
        ps["$limit"] = "\(limit)"
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Generates SoQL $offset parameter.
    public func offset(_ offset: Int) -> SODAQuery {
        var ps = self.parameters
        ps["$offset"] = "\(offset)"
        return SODAQuery (client: self.client, dataset: self.dataset, parameters: ps)
    }
    
    /// Performs the query asynchronously and sends all the results to the completion handler.
    public func get(_ completionHandler: @escaping (SODADatasetResult) -> Void) {
        client.get(dataset: dataset, withParameters: parameters, completionHandler)
    }

    /// Performs the query asynchronously and sends the results, one row at a time, to an iterator function.
    public func each(_ iterator: @escaping (SODARowResult) -> Void) {
        client.get(dataset: dataset, withParameters: parameters) { res in
            switch res {
            case .dataset (let data):
                for row in data {
                    iterator(.row (row))
                }
            case .error (let err):
                iterator(.error (err))
            }
        }
    }
}

