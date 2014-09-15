---
layout: with-sidebar
title: Swift SODA SDK
bodyclass: homepage
---

<div class="alert alert-info">
  <strong>Heads up!</strong>
  Swift (the language) is currently still in beta, but if you're a registered Apple developer, you can download the XCode Beta and try it out yourself. For more information, see the <a href="https://developer.apple.com/swift/resources/">Swift resources page</a>.
</div>

<img src="img/swift-logo.png" class="pull-right" alt="Swift"/>

[Swift](https://developer.apple.com/swift/) is an exciting new programming language from [Apple](http://www.apple.com). Part of the release of [iOS8](https://www.apple.com/ios/ios8/) for mobile devices and [OSX Yosemite](https://www.apple.com/osx/preview/) for Mac hardware, it makes it dramatically to develop Cocoa and Cocoa Touch apps without needing to write Objective C, yet it works alongside your existing Objective C code and libraries.

Our Swift SDK and sample app make it easy to get started with Swift and help you quickly get up to speed and start building mobile open data applications. Our SDK provides two components for you to leverage:

- [`SODAKit`](https://github.com/socrata/soda-swift/tree/master/SODAKit), which provides `SODAClient`, a wrapper library that helps you to connect to a [Socrata Open Data API](http://dev.socrata.com), formulate [SoQL queries](http://dev.socrata.com/docs/queries.html), and manipulate the data that is returned.
- [`SODASample`](https://github.com/socrata/soda-swift/tree/master/SODASample), a simple iOS app that queries the City of Chicago's dataset of [Alternative Fuel Locations](https://data.cityofchicago.org/Environment-Sustainable-Development/Alternative-Fuel-Locations/f7f2-ggz5) and renders them in a map view on your iPhone

## Getting Started

To get started with the Swift SODA SDK:

1. [Register for an application token](http://dev.socrata.com/docs/app-tokens.html) for your application
2. Clone [`soda-swift`](https://github.com/socrata/soda-swift)
3. Reference [`SODAKit/SODAClient.swift`](https://github.com/socrata/soda-swift/blob/master/SODAKit/SODAClient.swift) in Xcode
4. Initialize `SODAClient`:

{% highlight swift %}
let client = SODAClient(domain: "data.yourcity.gov", token: "yourapplicationtoken")
{% endhighlight %}

Once you have your client, you can get started issuing queries.

## Querying Datasets

Here is a simple filter query to find compressed natural gas stations in Chicago:

{% highlight swift %}
let fuelLocations = client.queryDataset("f7f2-ggz5")

fuelLocations.filterColumn ("fuel_type_code", "CNG").get { res in
  switch res {
  case .Dataset (let data):
    // Handle data
  case .Error (let error):
    // Deal with the error
  }
}
{% endhighlight %}

Note the use of `filterColumn` to get only compressed natural gas stations.

Also note that the final `get` function is asynchronous and that the last argument is a completion handler. For your convenience, `soda-swift` automatically schedules the handler on the main operation queue.

That completion handler is given an enumeration `SODADatasetResult` with two possible values:

* `Dataset` with an array of rows, if the query succeeded.
* `Error` with the `NSError`, if the query failed.

## Query Options

There are many more query options than just `filterColumn`. We could have also written:

{% highlight swift %}
fuelLocations.filter("fuel_type_code = 'CNG'")
{% endhighlight %}

We can also order the results:

{% highlight swift %}
fuelLocations.orderAscending("station_name")
{% endhighlight %}

We can then limit the results and control the offset to perform paging:

{% highlight swift %}
fuelLocations.limit(10).offset(0)
{% endhighlight %}

## Chaining Queries

Queries can be easily composed and stored in variables. This allows you to keep your code clean and easily construct derivative queries.

For example, we may have an app that has a base query called `fuelLocations`:

{% highlight swift %}
let fuelLocations = client.queryDataset("f7f2-ggz5")
{% endhighlight %}

The sample app allows the user to choose two types of stations: natural gas and electric. This decision is encapsulated in the query `stations`.

{% highlight swift %}
let userWantsNaturalGas = true // Get this from the UI

let stations = fuelLocations.filterColumn("fuel_type_code", userWantsNaturalGas ? "CNG" : "ELEC")
{% endhighlight %}

The app can also display the data sorted in two different directions and stores this in `orderedStations`:

{% highlight swift %}
let userWantsAscending = true // Get this from the UI

let orderedStations = userWantsAscending ?
    stations.orderAscending("station_name") :
    stations.orderDescending("station_name")
{% endhighlight %}

Now the app can easily query the results:

{% highlight swift %}
orderedStations.get { result in
    // Display the data or the error
}
{% endhighlight %}

## API Reference

The full API Reference can be found in [Reference.md](./Reference.m://github.com/socrata/soda-swift/blob/master/Reference.md).

## Sample App

A sample app that shows alternative fuel locations in Chicago is included.

1. Open [soda-swift.xcodeproj](https://github.com/socrata/soda-swift/tree/master/soda-swift.xcodeproj)
2. Modify [SODASample/AppDelegate.swift](https://github.com/socrata/soda-swift/blob/master/SODASample/AppDelegate.swift) to insert your access token
3. Ensure that the target `SODASample` is selected
4. **Run**


