//
//  XWSImportTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 12/12/22.
//  Copyright © 2022 SoftDesk. All rights reserved.
//
import XCTest
import Combine
import CoreData
@testable import DialControl

class XWSImportTests: XCTestCase {
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
    
    enum JSONTransformError : Error {
        case DecodingError
    }
    
    func transform<T: Decodable>(jsonString: String, then handler: @escaping Handler<T>) {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            try handler(.success(decoder.decode(T.self, from: jsonData)))
        } catch {
            let errorString: String = "error: \(error)"
            print(errorString)
            handler(.failure(JSONTransformError.DecodingError))
        }
    }
    
    typealias Handler<T> = (Result<T, Error>) -> Void
    
    func test(jsonString: String, then handler: @escaping (Result<SquadPilot, Error>) -> Void) {
        transform(jsonString: jsonString, then: handler)
    }
    
    func getCategory(upgrade: String) -> String? {
        if let u = UpgradeUtility.getCategory(upgrade: upgrade) {
            return u
        }
        return nil
    }
    
    func test_transform_squadPilot() {
        func buildUpgrades() -> SquadPilotUpgrade {
            var newUpgrades = SquadPilotUpgrade()
            newUpgrades._talent = []
            newUpgrades._talent?.append("elusive")
            
            newUpgrades._cannon = []
            newUpgrades._cannon?.append("ioncannon")
            
            return newUpgrades
        }
        
        var noUpgradesPilot:SquadPilot?
        var withUpgradesPilot:SquadPilot?
        
        let noUpgradesHandler: Handler<SquadPilot> = { result in
            switch(result) {
                case .success(var qb):
                    print(qb)
                    noUpgradesPilot = qb
                    noUpgradesPilot?.upgrades = buildUpgrades()
                    
                case .failure(let _):
                    print("Failure")
            }
        }
        
        let upgradesHandler: Handler<SquadPilot> = { result in
            switch(result) {
                case .success(var qb):
                    print(qb)
                    withUpgradesPilot = qb
                    
                case .failure(let _):
                    print("Failure")
            }
        }
        
        // Build & verify squadPilotWithNoUpgrades
        transform(jsonString: squadPilotWithNoUpgrades, then: noUpgradesHandler)
        
        // Build & verify squadPilotWithUpgrades
        transform(jsonString: squadPilotWithUpgrades, then: upgradesHandler)
        
        // Add upgrades to squadPilotWithNoUpgrades object
        // struct SquadPilotUpgrade: Codable
        // var upgrades: SquadPilotUpgrade? { return _upgrades ?? nil }
        // newUpgrades._talent?.append("elusive")
        // newUpgrades._cannon?.append("ioncannon")
        
        // Compare & assert on withUpgradesPilot.json == json
        if let noUpgrades = noUpgradesPilot {
            print(noUpgrades.description)
            
            if let withUpgrades = withUpgradesPilot {
                print(withUpgrades.description)
                
                XCTAssertEqual(noUpgrades.description, withUpgrades.description)
            }
        }
    }

    let squadPilotWithNoUpgrades = """
        {
          "id":"idenversio",
          "name":"idenversio",
          "points":3,
          "ship":"tielnfighter"
        }
    """
        
    let squadPilotWithUpgrades = """
        {
          "id":"idenversio",
          "name":"idenversio",
          "points":3,
          "ship":"tielnfighter",
          "upgrades":{
            "talent":["elusive"],
            "cannon":["ioncannon"]
            }
        }
    """
        
        // Build a SquadPilot from shipWithNoUpgrades
        // Add the upgrades to the squad pilot
        // Create JSON from the squad pilot
        // Assert if the same as shipWithUpgrades
    
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
}
