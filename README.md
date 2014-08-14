# soda-swift

**soda-swift** is a native [Swift](https://developer.apple.com/library/prerelease/mac/documentation/Swift/Conceptual/Swift_Programming_Language) library to access [Socrata OpenData](https://opendata.socrata.com) servers. It is compatible with iOS 8 and OS X 10.10.


## Getting Started

### 1. [Get an access token](http://dev.socrata.com/register) for your app

### 2. Reference [SODAKit/SODAClient.swift](./SODAKit/SODAClient.swift) in Xcode

### 3. Initialize a `SODAClient`

	let client = SODAClient(domain: "(Domain name of the server)", token: "(Your app's access token)")

For example,

	let client = SODAClient(domain: "data.cityofchicago.org", token: "Uo25eXiX14zEd2K6EKAkeMIDW")

(that token won't work)

### 4. Query for data

Here is a simple filter query to find compressed natural gas stations in Chicago:

    let fuelLocations = client.queryDataset("alternative-fuel-locations")

    fuelLocations.filterColumn ("fuel_type_code", "CNG").get { res in
        switch res {
        case .Dataset (let data):

            // Display the data

        case .Error (let error):

        	// Show the error

        }
    }

Note the use of `filterColumn` to get only compressed natural gas stations.

Also note that the final `get` function is asynchronous and that the last argument is a completion handler. For your convenience, **soda-swift** automatically schedules the handler on the main operation queue.

That completion handler is given an enumeration `SODADatasetResult` with two possible values:

* **Dataset** with an array of rows if the query succeeded.
* **Error** with the `NSError` if the query failed.


#### Query Options

There are many more query options than just `filterColumn`. We could have also written:

    fuelLocations.filter("fuel_type_code = 'CNG'")

We can also order the results:

    fuelLocations.orderAscending("station_name")

We can then limit the results and control the offset to perform paging:

    fuelLocations.limit(10).offset(0)


#### Chaining Queries

Queries can be easily composed and stored in variables. This allows you to keep your code clean and easily construct derivative queries.

For example, we may have an app that has a base query called `fuelLocations`:

    let fuelLocations = client.queryDataset("alternative-fuel-locations")

The app allows the user to choose two types of stations: natural gas and electric. This decision is encapsulated in the query `stations`.

    let userWantsNaturalGas = true // Get this from the UI

    let stations = fuelLocations.filterColumn("fuel_type_code", userWantsNaturalGas ? "CNG" : "ELEC")

The app can also display the data sorted in two different directions and stores this in `orderedStations`:

    let userWantsAscending = true // Get this from the UI

    let orderedStations = userWantsAscending ?
        stations.orderAscending("station_name") :
        stations.orderDescending("station_name")

Now the app can easily query the results:

    orderedStations.get { result in

        // Display the data or the error

    }



## API Reference

The full API Reference can be found in [Reference.md](./Reference.md).

## Sample App

A sample app that shows alternative fuel locations in Chicago is included.

1. Open [soda-swift.xcodeproj](./soda-swift.xcodeproj)
2. Modify [SODASample/AppDelegate.swift](./SODASample/AppDelegate.swift) to insert your access token
3. Ensure that the target **SODASample** is selected
4. **Run**

