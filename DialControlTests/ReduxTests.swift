//
//  ReduxTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 4/22/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import CoreData
import Foundation
import XCTest
@testable import DialControl

extension DialControlTests {
    func testDeleteAllSquads() {
        // Subscribe to the store
        self.store?.$state
            .sink(receiveValue: { state in
                print("state.faction.displayDeleteAllSquadsConfirmation = \(state.faction.displayDeleteAllSquadsConfirmation)")
                XCTAssertEqual(state.faction.displayDeleteAllSquadsConfirmation, false, "Display Delete all Squads confirmation is incorrect")
            }).store(in: &cancellables)
    }
    
    func testLoadAllSquads() {
        // Subscribe to the store
        self.store?.$state
            .dropFirst(2)
            .sink(receiveValue: { state in
            print("state.faction.squadDataList.count = \(state.faction.squadDataList.count)")
            XCTAssertEqual(state.faction.squadDataList.count, 4, "Squad list count from store is incorrect")
        }).store(in: &cancellables)
        
        // Send the store an event
        self.store?.send(.faction(action: .loadSquads))
    }
}
