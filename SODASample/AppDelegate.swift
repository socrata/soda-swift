//
//  AppDelegate.swift
//  SODASample
//
//  Created by Frank A. Krueger on 8/10/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    
    // Register for access tokens here: http://dev.socrata.com/register
    
    let client = SODAClient(domain: "data.cityofchicago.org", token: "(Put your access token here)")
    
    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        return true
    }

}

