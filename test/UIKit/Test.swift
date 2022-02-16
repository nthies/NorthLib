//
//  Test.swift
//
//  Created by Norbert Thies on 30.08.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit
import NorthUIKit

import XCTest

extension XCTestCase: DoesLog {}

class DefaultsTests: XCTestCase {
  
  var defaults = Defaults.singleton
  
  @Default("testCGFloat")
  var testCGFloat: CGFloat
  
  override func setUp() {
    super.setUp()
    Log.minLogLevel = .Debug
    defaults.suite = "taz"
    defaults.onChange { arg in
      print("Notification: \(arg.0)=" +
              "\"\(arg.1 ?? "nil")\" in scope " +
              "\"\(arg.2 ?? "nil")\"")
      
    }
    let iPhoneDefaults: [String:String] = [
      "key1" : "iPhone-value1",
      "key2" : "iPhone-value2"
    ]
    let iPadDefaults: [String:String] = [
      "key1" : "iPad-value1",
      "key2" : "iPad-value2"
    ]
    defaults.setDefaults(values: Defaults.Values(scope: "iPhone", values: iPhoneDefaults), isNotify: true)
    defaults.setDefaults(values: Defaults.Values(scope: "iPad", values: iPadDefaults), isNotify: true)
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testDefaults() {
    let dfl = Defaults.singleton
    dfl[nil,"test"] = "non scoped"
    dfl["iPhone","test"] = "iPhone"
    dfl["iPad","test"]   = "iPad"
    XCTAssertEqual(dfl[nil,"test"], "non scoped")
    if Device.isIphone {
      XCTAssertEqual(dfl["test"], "iPhone")
      XCTAssertEqual(dfl["key1"], "iPhone-value1")
      XCTAssertEqual(dfl["key2"], "iPhone-value2")
    }
    else if Device.isIpad {
      XCTAssertEqual(dfl["test"], "iPad")      
      XCTAssertEqual(dfl["key1"], "iPad-value1")
      XCTAssertEqual(dfl["key2"], "iPad-value2")
    }
  }
  
  func testWrappers() {
    testCGFloat = 0
    $testCGFloat.onChange { val in print(val) }
    testCGFloat = 15
    XCTAssertEqual(testCGFloat, 15)
  }

} // class DefaultsTest

