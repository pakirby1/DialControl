//
//  ReduxTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 4/22/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData
import Foundation
import XCTest
@testable import DialControl

extension DialControlTests {
    func testA() {
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Used only if we have a unique constraint on our CoreData entity?
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let diContainer = DIContainer()
        diContainer.registerServices(moc: moc)
        
        let store: MyAppStore = MyAppStore(
            state: MyAppState.init(faction: FactionSquadListState(),
                                   squad: MySquadViewState(),
                                   ship: MyShipViewState()),
            reducer: myAppReducer,
            environment: MyEnvironment(squadService: diContainer.squadService,
                               pilotStateService: diContainer.pilotStateService,
                               jsonService: diContainer.jsonService)
        )
        
        // Send the store an event
        
        // XCTAssert()
    }
}
