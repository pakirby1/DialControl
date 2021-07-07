//
//  DialControlTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 2/15/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import CoreData
import Foundation
import XCTest
@testable import DialControl

class DialControlTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    var store: MyAppStore?
    
    override func setUp() {
        func buildState() -> MyAppState {
            MyAppState.init(faction: FactionSquadListState(),
                                   squad: MySquadViewState(),
                                   ship: MyShipViewState(),
                                   xwsImport: MyXWSImportViewState(),
                                   factionFilter: FactionFilterState(),
                                   tools: ToolsViewState())
        }
        
        func buildEnvironment() -> MyEnvironment {
            MyEnvironment(squadService: diContainer.squadService,
                pilotStateService: diContainer.pilotStateService,
                jsonService: diContainer.jsonService,
                imageService: diContainer.imageService)
        }
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Used only if we have a unique constraint on our CoreData entity?
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let diContainer = DIContainer()
        diContainer.registerServices(moc: moc)
        
        self.store = MyAppStore(
            state: buildState(),
            reducer: myAppReducer,
            environment: buildEnvironment()
        )
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
