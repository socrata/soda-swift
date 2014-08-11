//
//  SODAClientTests.swift
//  SODATests
//
//  Created by Frank A. Krueger on 8/9/14.
//  Copyright (c) 2014 Socrata, Inc. All rights reserved.
//

import UIKit
import XCTest

class SODAClientTests: XCTestCase {
    
    let token = "(Put your access token here)"
    
    // TODO: Test this once we find valid row IDs
    func ignoreTestGetRow() {
        let e = expectationWithDescription("get")
        let client = SODAClient(domain: "data.cityofchicago.org", token: token)
        
        client.getRow("62312", inDataset:"alternative-fuel-locations") { res in
            switch res {
            case .Row (let json):
                XCTAssertGreaterThanOrEqual(json.count, 20, "At least 20 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testMissingRow() {
        let e = expectationWithDescription("get")
        let client = SODAClient(domain: "data.cityofchicago.org", token: token)
        
        client.getRow("8923884", inDataset:"alternative-fuel-locations") { res in
            switch res {
            case .Row (let json):
                XCTAssert(false, "Row should not exist")
            case .Error (let err):
                XCTAssert(true, "Pass")
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNoFilter() {
        let e = expectationWithDescription("get")
        let client = SODAClient(domain: "data.cityofchicago.org", token: token)
        
        client.queryDataset("alternative-fuel-locations", limit: 30) { res in
            switch res {
            case .Dataset (let json):
                XCTAssertEqual(json.count, 30, "30 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSimpleFilter() {
        let e = expectationWithDescription("get")
        let client = SODAClient(domain: "data.cityofchicago.org", token: token)
        
        client.queryDataset("alternative-fuel-locations", withFilters: ["fuel_type_code": "CNG"]) { res in
            switch res {
            case .Dataset (let json):
                XCTAssertGreaterThanOrEqual(json.count, 20, "At least 20 results")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testSimpleFilterWithLimit() {
        let e = expectationWithDescription("get")
        let client = SODAClient(domain: "data.cityofchicago.org", token: token)
        
        client.queryDataset("alternative-fuel-locations", withFilters: ["fuel_type_code": "CNG"], limit: 10) { res in
            switch res {
            case .Dataset (let json):
                XCTAssertEqual(json.count, 10, "Limited to 10")
            case .Error (let err):
                XCTAssert(false, err.userInfo.debugDescription)
            }
            e.fulfill()
        }
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

}
