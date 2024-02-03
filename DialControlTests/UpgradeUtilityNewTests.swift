//
//  UpgradeUtilityNewTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 2/1/24.
//  Copyright © 2024 SoftDesk. All rights reserved.
//

import Foundation
import XCTest
@testable import DialControl

class UpgradeUtilityNewTests: XCTestCase {
    func test_initialization() {
        var upgradeUtility = UpgradeUtilityNew()
        XCTAssertTrue(upgradeUtility.upgradesData.categoryToUpgradesDictionary.count > 0)
    }
}
