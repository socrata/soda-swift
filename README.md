# soda-swift

Swift library to access [Socrata OpenData](https://opendata.socrata.com) servers. It is compatible with iOS 8 and OS X 10.10.


## Getting Started

### 1. [Get an access token for your app](http://dev.socrata.com/register)

### 2. Reference [SODAKit/SODAClient.swift](./SODAKit/SODAClient.swift) in your app

### 3. Initialize a client

	let client = SODAClient(domain: "(Domain name of the server)", token: "(Your app's access token)")

For example,

	let client = SODAClient(domain: "data.cityofchicago.org", token: "Uo25eXiX14zEd2K6EKAkeMIDW")

(that token won't work)

### 4. Query for data

Here is a simple filter query to find charging stations in Chicago:

    client.queryDataset("alternative-fuel-locations", withFilters: ["fuel_type_code": "CNG"], limit: 200) { res in
        switch res {
        case .Dataset (let data):

            // Display data

        case .Error (let error):

        	// Show the error

        }
    }

Note that the `queryDataset` function is asynchronous and that the last argument is a completion handler.

That completion handler is given an enumeration `SODADatasetResult` with two possible values:

* **Dataset** if the query succeeded. The array of rows is associated with it.
* **Error** if there was an error. The `NSError` is associated with it.


## Sample App

A sample app that shows alternative fuel locations in Chicago is included.

1. Open [soda-swift.xcodeproj](./soda-swift.xcodeproj)
2. Modify [SODASample/AppDelegate.swift](./SODASample/AppDelegate.swift) to insert your access token
3. Ensure that the target **SODASample** is selected
4. **Run**

