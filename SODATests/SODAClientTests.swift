//
//  SODAClientTests.swift
//  SODATests
//
//  Created by Frank A. Krueger on 8/9/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import UIKit
import XCTest

let token = "(Put your access token here)"

class SODAClientTests: XCTestCase {
    
    let client = SODAClient(domain: "data.cityofchicago.org", token: token)
    
    let demoClient = SODAClient (domain: "soda.demo.socrata.com", token: token)
    
    
    // TODO: Test this once we find valid row IDs
    func ignoreTestRowGet() {
        let e = expectationWithDescription("get")
        
        client.getRow("62312", inDataset:"alternative-fuel-locations") { res in
            switch res {
            case .Row (let row):
                XCTAssertGreaterThanOrEqual(row.count, 20, "At least 20 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testRowMissing() {
        let e = expectationWithDescription("get")
        
        client.getRow("8923884", inDataset:"alternative-fuel-locations") { res in
            switch res {
            case .Row (let row):
                XCTAssert(false, "Row should not exist")
            case .Error (let err):
                XCTAssert(true, "Pass")
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testQueryNoFilterWithLimit() {
        let e = expectationWithDescription("get")
        
        client.queryDataset("alternative-fuel-locations").limit(30).get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertEqual(data.count, 30, "30 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testQueryNoFilter() {
        let e = expectationWithDescription("get")
        
        client.queryDataset("alternative-fuel-locations").get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertGreaterThan(data.count, 100, "At least 100 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testQuerySimpleFilter() {
        let e = expectationWithDescription("get")
        
        client.queryDataset("alternative-fuel-locations").filterColumn("fuel_type_code", "CNG").get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertGreaterThanOrEqual(data.count, 20, "At least 20 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testQuerySimpleFilterWithLimit() {
        let e = expectationWithDescription("get")
        
        client.queryDataset("alternative-fuel-locations").filterColumn("fuel_type_code", "CNG").limit(10).get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertEqual(data.count, 10, "Limited to 10")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testQueryFullText() {
        let e = expectationWithDescription("get")
        
        client.queryDataset("alternative-fuel-locations").fullText("University").get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertGreaterThanOrEqual(data.count, 1, "At least 1")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testQueryGroup() {
        let e = expectationWithDescription("get")
        
        demoClient.queryDataset("4tka-6guv").select("region,MAX(magnitude)").group ("region").get { res in
            switch res {
            case .Dataset (let data):
                XCTAssertGreaterThanOrEqual(data.count, 1000, "At least 1")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    class Counter {
        var count = 0
        func increment() { count++ }
    }
    
    func testQueryEach() {
        let e = expectationWithDescription("get")
        
        let c = Counter()
        
        client.queryDataset("alternative-fuel-locations").filterColumn("fuel_type_code", "CNG").each {[c] res in
            switch res {
            case .Row (let row):
                c.increment()
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            
            if c.count >= 20 {
                e.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }


}
