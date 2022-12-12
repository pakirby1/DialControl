//
//  StoreTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 7/7/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import XCTest
import Combine
import CoreData
@testable import DialControl

class StoreTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    var store: MyAppStore?
    
    override func setUp() {
        func buildState() -> MyAppState {
            MyAppState.init(faction: FactionSquadListState(),
                                   squad: MySquadViewState(),
                                   ship: MyShipViewState(),
                                   xwsImport: MyXWSImportViewState(),
                                   factionFilter: FactionFilterState(),
                                   tools: ToolsViewState(), upgrades: UpgradesState())
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
        
        let cache = CacheService()
        let diContainer = DIContainer()
        diContainer.registerServices(moc: moc, cacheService: cache)
        
        self.store = MyAppStore(
            state: buildState(),
            reducer: myAppReducer,
            environment: buildEnvironment()
        )
    }
    
    /// <#Description#>
    func testDownloadAllImages() {
        func handleCompletion(completion: Subscribers.Completion<Never>) {
            print(".sink() received the completion", String(describing: completion))
            
            switch completion {
                case .finished:
                    print("finished")
                    break
                case .failure(let anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                    break
            }
            expectation.fulfill()
        }
        
        func handleValue(value: MyAppState) {
            let dies = value.tools.downloadImageEventState
            receiveCount += 1
            collectedSequence.append(dies)
            print(".sink() data received \(dies)")
        }
        
        let expectation = XCTestExpectation(description: self.debugDescription)
        var receiveCount = 0
        var collectedSequence: [DownloadImageEventState] = []
        
        let cancellable = store?.$state
            .sink(receiveCompletion: handleCompletion,
            receiveValue: handleValue)
        
        store?.send(MyAppAction.tools(action: .downloadAllImages))
        
        wait(for: [expectation], timeout: 60.0)
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(receiveCount, 6)
    }

    func testStorePerformance() {
        measure {
            func handleCompletion(completion: Subscribers.Completion<Never>) {
                print(".sink() received the completion", String(describing: completion))
                
                switch completion {
                    case .finished:
                        print("finished")
                        break
                    case .failure(let anError):
                        XCTFail("No failure should be received from empty")
                        print("received error: ", anError)
                        break
                }
                expectation.fulfill()
            }
        
            func handleValue(value: MyAppState) {
                let currentRound = value.faction.currentRound
                receiveCount += 1
                collectedSequence.append(currentRound)
                print(".sink() data received \(currentRound)")
            }
            
            let expectation = XCTestExpectation(description: self.debugDescription)
            var receiveCount = 0
            var collectedSequence: [Int] = []
            
            let cancellable = store?.$state
                .sink(receiveCompletion: handleCompletion,
                receiveValue: handleValue)
            
            store?.$state.sink { state in
                XCTAssertEqual(state.faction.currentRound, 0)
//                        XCTAssertEqual(state, .populated)
                        expectation.fulfill()
            }.store(in: &cancellables)

            
            let currentRound = collectedSequence.last ?? 0
            store?.send(MyAppAction.faction(action: .setRound(3)))
            
            wait(for: [expectation], timeout: 60.0)
            XCTAssertNotNil(cancellable)
        }
        
    }
}
