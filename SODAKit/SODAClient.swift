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

/// Default TTL for cached responses, 5 minutes.
public let SODADefaultCacheTTL: TimeInterval = (60 * 5)

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
    private var cachedResponsesByURL: [String: CachedResponse] = [:]
    private var inProgressRequestsByURL: [String: InProgressRequest] = [:]
    private let ttl: TimeInterval
    private var cacheCleanupTimer: Timer?
    /// Initializes this client to communicate with a SODA endpoint.
    public init(domain: String, token: String, ttl: TimeInterval =  SODADefaultCacheTTL) {
        self.domain = domain
        self.token = token
        self.ttl = ttl
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
        let possibleUrlToSend = URL(string: url)
        guard let urlToSend = possibleUrlToSend else { return }
        // Build the request
        let request = NSMutableURLRequest(url: urlToSend)
        request.addValue("application/json", forHTTPHeaderField:"Accept")
        request.addValue(self.token, forHTTPHeaderField:"X-App-Token")
        
        // We sync the callback with the main thread to make UI programming easier
        let syncCompletion: SODADatasetCompletionHandler = { res in OperationQueue.main.addOperation { completionHandler (res) } }
        // Check to see if we have a cached response.
        let cachedResponse = self.cachedResponsesByURL[urlToSend.absoluteString]
        if let cache = cachedResponse {
            // The response will check to see if it is still valid according to its TTL
            if cache.isValid {
                // If the response is valid, interpret the response as if it came from the server
                self.interpretResponse(
                    jsonResult: cachedResponse?.response,
                    syncCompletion: syncCompletion
                )
                return
            } else {
                // Cached response is invalid and should be removed
                self.cachedResponsesByURL.removeValue(forKey: urlToSend.absoluteString)
            }
        }
        // If there is no cached response, check to see if there is a request already in progress to this URL.
        if let inProgessRequest = self.inProgressRequestsByURL[urlToSend.absoluteString] {
            // If request is in progress, then add the completion handler to the in progress request.
            inProgessRequest.completionHandlers.append(syncCompletion)
        } else {
            // No request to this endpoint is in progress, create an InProgressRequest to keep track of completion handlers and then start the request.
            let inProgressRequest = InProgressRequest(url: urlToSend)
            inProgressRequest.completionHandlers.append(syncCompletion)
            
            // Store the in progress response by the URL so we can check for it later.
            self.inProgressRequestsByURL[urlToSend.absoluteString] = inProgressRequest
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, reqError in
                self.handleResponse(data: data, response: response, reqError: reqError)
            }
            task.resume()
        }
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, reqError: Error?) {
        guard let url = response?.url else { return }
        var error: Error?
        var jsonResult: Any!
        var cachedResponse: CachedResponse?
        // Check if there was an error from the server
        if let reqError = reqError {
            error = reqError
        } else {
            // Convert payload to swift objects
            do {
                jsonResult = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            } catch let jsonError {
                error = jsonError
                jsonResult = nil
            }
            // If there is no error, we've had a successful response and want to cache it. Do not create cache objects at all if ttl is 0
            if error == nil && self.ttl > 0 {
                cachedResponse = CachedResponse(
                    response: jsonResult,
                    ttl: self.ttl
                )
            }
            
            // Create a timer to schedule the cleanup job so cache does not get too big.
            self.setCacheInvalidationTimer()
            self.cachedResponsesByURL[url.absoluteString] = cachedResponse
        }
        self.inProgressRequestsByURL[url.absoluteString]?.completionHandlers.forEach({ (syncCompletion) in
            if let error = error {
                syncCompletion(.error(error))
            } else {
                self.interpretResponse(jsonResult: jsonResult, syncCompletion: syncCompletion)
            }
        })
        
        // Request has been handled, remove the stored object from the dictionary.
        self.inProgressRequestsByURL.removeValue(forKey: url.absoluteString)
    }
    
    fileprivate func interpretResponse(jsonResult: Any!, syncCompletion: @escaping SODADatasetCompletionHandler) {
        if let array = jsonResult as? [[String: Any]] {
            syncCompletion(.dataset (array))
        } else if let dict = jsonResult as? [String: Any] {
            if let errorMessage = dict["message"] {
                syncCompletion(.error (NSError(domain: "SODA", code: 0, userInfo: ["Error": errorMessage])))
                return
            }
            syncCompletion(.dataset ([dict]))
        }
    }
    
    /// Converts an NSDictionary into a query string.
    fileprivate class func paramsToQueryString (_ params: [String: String]) -> String {
        var s = ""
        var head = ""
        for (key, value) in params {
            let sk = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let sv = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            s += head + sk!+"="+sv!
            head = "&"
        }
        return s
    }
    
    /// Create a timer to invalidate cache when its ready
    fileprivate func setCacheInvalidationTimer() {
        self.cacheCleanupTimer?.invalidate()
        self.cacheCleanupTimer = nil
        DispatchQueue.main.async {
            self.cacheCleanupTimer = Timer.scheduledTimer(
                timeInterval: self.ttl,
                target: self,
                selector: #selector(self.timeToInvalidateCache(_:)),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    /// Selector to be called after one cycle of the TTL.
    @objc func timeToInvalidateCache(_ timer: Timer) {
        guard self.cacheCleanupTimer != nil else { return }
        self.cacheCleanupTimer?.invalidate()
        self.cacheCleanupTimer = nil
        
        self.cachedResponsesByURL.removeAll()
    }
}

/// SODAQuery extension to SODAClient
public extension SODAClient {
    /// Get a query object that can be used to query the client using a fluent syntax.
    public func query(dataset: String) -> SODAQuery {
        return SODAQuery (client: self, dataset: dataset)
    }
}

/// Assists in the construction of a SoQL query.
public class SODAQuery {
    public let client: SODAClient
    public let dataset: String
    public let parameters: [String: String]
    
    /// Initializes all the parameters of the query
    public init(client: SODAClient, dataset: String, parameters: [String: String] = [:]) {
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

private class CachedResponse {
    var isValid: Bool {
        return Date().timeIntervalSince(self.fetchedAt) < self.ttl
    }
    let response: Any?
    let fetchedAt: Date
    let ttl: TimeInterval
    init (response: Any?, ttl: TimeInterval) {
        self.fetchedAt = Date()
        self.response = response
        self.ttl = ttl
    }
}

private class InProgressRequest {
    let url: URL
    var completionHandlers: [SODADatasetCompletionHandler] = []
    init (url: URL) {
        self.url = url
    }
}

