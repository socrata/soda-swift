# Maintenance

The document describes implementation decisions made in the development of **soda-swift**. You should read it if you want to modify the code or if you're just curious.

## Code

### SODAClient

The client uses `NSURLSession.sharedSession().dataTaskWithRequest` to make the HTTPS request. The library does not modify the default `sharedSession`.

`NSJSONSerialization.JSONObjectWithData` is then used to parse the response.

The result of parsing is checked for an error. If the response looks like an error message, then that error is bubbled up in a new `NSError` object.

If it does not appear to be an error, and is an array, then it is returned.

The client also takes care to schedule its callbacks on `NSOperationQueue.mainQueue()`. This is just to make UI programming easier.

### SODADatasetResult

For someone new to Swift or functional programming, the `SODADatasetResult` might seem a little odd. It is a discrimated union with two possible values `Success` or `Error`. The fun part is that each of those values is associated with some data:

    enum SODADatasetResult {
        case Dataset ([[String: AnyObject]])
        case Error (NSError)
    }

You can get to the data associated with these values using pattern matching in a `switch` statement:

    switch result {
    case .Dataset (let data):
        // Do something with `data`
    case .Error (let error):
        // Inform the user of the `error`
    }

This perfectly encapsulates the results of an asynchronous call: it can either succeed or fail and we can pass that result as a single argument to the completion handler.


### SODAQuery

Queries are immutable objects that contain chaining methods that return new queries with different options.

They are implemented as a thin wrapper around a `[String: String]` that represents the URL query sent to the OpenData server.


## Project

The project is a single Xcode 6 project that contains 3 targets:

### SODAKit

The main client library as a framework.

Currently everything is stuffed into SODAClient.swift so that the whole library can be imported into other apps with just a file include.

This will become a proper compiled library that can be referenced en masse eventually. Once that is done, the `SODAQuery` class and its extension should be moved to their own Swift file.

### SODATests

Xcode unit tests for the library.

These tests require an internet connection to work. Also note that they are asynchronous.

### SODASample

This is a sample iPhone app with two tabs.

The Query tab (`QueryViewController.swift`) contains a reference to the `SODAClient` and performs the query when displayed and when the user pulls to refresh. Errors are displayed in an alert if the query fails.

If the query succeeds, the results are passed on to the map tab (`MapViewController.swift`). It parses the location info and displays them as annotations on the map.






