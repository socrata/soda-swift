# API Reference

## SODAClient

    init(domain: String, token: String)

Initializes this client to communicate with a SODA endpoint.

    func getRow(row: String, inDataset: String, _ completionHandler: SODARowCompletionHandler)

Gets a row using its identifier. See [http://dev.socrata.com/docs/row-identifiers.html]()

    func queryDataset(dataset: String) -> SODAQuery {
        return SODAQuery (client: self, dataset: dataset)
    }

Get a [query object][SODAQuery] that can be used to query the client using a fluent syntax.

    func getDataset(dataset: String, withFilters: [String: String], limit: Int = SODADefaultLimit, offset: Int = 0, _ completionHandler: SODADatasetCompletionHandler)

Asynchronously gets a dataset using a simple filter query. See [http://dev.socrata.com/docs/filtering.html]()

    func getDataset(dataset: String, withParameters: [String: String], _ completionHandler: SODADatasetCompletionHandler)

Low-level access for asynchronously getting a dataset. You should use [SODAQueries][SODAQuery] instead of this. See [http://dev.socrata.com/docs/queries.html]()

    func queryDataset(dataset: String) -> SODAQuery

Get a query object that can be used to query the client using a fluent syntax.

### SODADatasetResult

The result of an asynchronous SODAClient.getDataset call. It can either succeed with data or fail with an error.

    enum SODADatasetResult {
        case Dataset ([[String: AnyObject]])
        case Error (NSError)
    }

### SODARowResult

The result of an asynchronous SODAClient.getRow call. It can either succeed with data or fail with an error.

    enum SODARowResult {
        case Row ([String: AnyObject])
        case Error (NSError)
    }


## SODAQuery

    init(client: SODAClient, dataset: String, parameters: [String: String] = [:])

Initializes all the parameters of the query

    func select(select: String) -> SODAQuery

Generates SoQL $select parameter. Use the AS operator to modify the output.
    
    func filter(filter: String) -> SODAQuery

Generates SoQL $where parameter. Use comparison operators and AND, OR, NOT, IS NULL, IS NOT NULL. Strings must be single-quoted.
    
    func filterColumn(column: String, _ value: String) -> SODAQuery

Generates simple filter parameter. Multiple filterColumns are allowed in a single query.

    func fullText(fullText: String) -> SODAQuery

Generates SoQL $q parameter. This uses a multi-column full text search.
    
    func orderAscending(column: String) -> SODAQuery

Generates SoQL $order ASC parameter.

    func orderDescending(column: String) -> SODAQuery

Generates SoQL $order DESC parameter.
    
    func group(column: String) -> SODAQuery

Generates SoQL $group parameter. Use select() with aggregation functions like MAX and then name the column to group by.
    
    func limit(limit: Int) -> SODAQuery

Generates SoQL $limit parameter. The default limit is 1000.
    
    func offset(offset: Int) -> SODAQuery

Generates SoQL $offset parameter.
    
    func get(completionHandler: SODADatasetResult -> Void)

Performs the query asynchronously and sends all the results to the completion handler.

    func each(iterator: SODARowResult -> Void)

Performs the query asynchronously and sends the results, one row at a time, to an iterator function.

