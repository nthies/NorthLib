//
//  StringExtensionTests.swift
//
//
//  Created by Ringo Müller on 22.11.24.
//

import XCTest

final class StringExtensionTests: XCTestCase {

    func testLastPathComponentsWithFullPath() {
        let fullPath = "/Library/Developer/CoreSimulator/Devices/aaa/data/Containers/Data/Application/bbb/Library/Application Support/taz/taz/2024-01-11"
        let result = fullPath.lastPathComponents(4)
        XCTAssertEqual(result, "/Application Support/taz/taz/2024-01-11", "Expected to extract the last 4 components.")
    }

    func testLastPathComponentsWithShortPath() {
        let shortPath = "/a/b"
        let result = shortPath.lastPathComponents(4)
        XCTAssertEqual(result, "/a/b", "Expected to return the full path when fewer components are available.")
    }

    func testLastPathComponentsWithExactCount() {
        let path = "/x/y/z"
        let result = path.lastPathComponents(3)
        XCTAssertEqual(result, "/x/y/z", "Expected to return the full path as the count matches the number of components.")
    }

    func testLastPathComponentsWithOneComponent() {
        let path = "/onlyOne"
        let result = path.lastPathComponents(1)
        XCTAssertEqual(result, "/onlyOne", "Expected to extract only the last component.")
    }

    func testLastPathComponentsWithZeroComponents() {
        let path = "/a/b/c"
        let result = path.lastPathComponents(0)
        XCTAssertEqual(result, "", "Expected an empty string when 0 components are requested.")
    }

    func testLastPathComponentsWithNoLeadingSlash() {
        let path = "no/leading/slash"
        let result = path.lastPathComponents(2)
        XCTAssertEqual(result, "/leading/slash", "Expected the last two components to be extracted correctly.")
    }
}
