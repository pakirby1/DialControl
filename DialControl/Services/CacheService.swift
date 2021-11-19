//
//  CacheService.swift
//  DialControl
//
//  Created by Phil Kirby on 10/29/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import CombineExt

protocol CacheServiceProtocol {
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
}

class CacheNew<Key: Hashable & CustomStringConvertible, Value> {
    private var store = [Key: Value]()

    func getValue(key: Key, factory: @escaping (Key) -> Value) -> Value {
        if let value = store[key] {
            global_os_log("CacheNew.getValue cache hit", "\(key.description)")
            return value
        } else {
            global_os_log("CacheNew.getValue cache miss", "\(key.description)")
            let value = factory(key)
            store[key] = value
            global_os_log("CacheNew.getValue inserted: ", "\(key.description)")
            global_os_log("CacheNew.getValue store count: ", "\(store.count)")
            return value
        }
    }
    
    func getValue(key: Key, factory: @escaping (Key) -> Result<Value, Error>) -> Result<Value, Error> {
        if let value = store[key] {
            global_os_log("CacheNew.getValue cache hit", "\(key.description)")
            return .success(value)
        } else {
            global_os_log("CacheNew.getValue cache miss", "\(key.description)")
            let value = factory(key)
            
            switch(value) {
                case .success(let x):
                    store[key] = x
                    global_os_log("CacheNew.getValue inserted: ", "\(key.description)")
                    global_os_log("CacheNew.getValue store count: ", "\(store.count)")
                    return value
                    
                case .failure( _):
                    return value
            }
        }
    }
}

class CacheService : CacheServiceProtocol {
    private var shipCache = CacheNew<ShipKey, Ship>()
    private var upgradeCache = CacheNew<String, [Upgrade]>()
    
    enum CacheError : Error {
        case FactoryFailure(String)
    }
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never> {
        getShipV1(squad: squad, squadPilot: squadPilot, pilotState: pilotState)
    }
    
    private func getShipV1(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheService.getShip")
        
        func getShipFromCache() -> Ship? {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheService.getShipFromCache.getShipFromFile", shipKey.description)
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                return ship
            }
            
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            global_os_log("CacheService.getShip.getShipFromCache", shipKey.description)
            
            return shipCache.getValue(key: shipKey, factory: getShipFromFile(shipKey:))
        }
            
        func getPilot(ship: Ship) -> ShipPilot {
            func getUpgradesFromCache() -> [Upgrade] {
                func getUpgrade(key: UpgradeKey) -> Upgrade? {
                    /// Get upgrade from JSON
                    global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade: \(key)")
                    let upgrades = upgradeCache.getValue(key: key.category, factory: UpgradeUtility.getUpgrades(upgradeCategory:))
                    
                    let ret = upgrades.filter{ $0.xws == key.xws }.first
                    global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade", ret?.xws ?? "Upgrade Not Found")
                    
                    return ret
                }
                
                if let upgradeKeys = squadPilot.upgrades?.allUpgradeKeys {
                    return upgradeKeys.compactMap(getUpgrade)
                }
                
                return []
            }
            
            global_os_log("CacheService.getShip.getPilot")
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            allUpgrades = getUpgradesFromCache()
            
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)
        }
        
        guard let ship = getShipFromCache() else {
            return Empty().eraseToAnyPublisher()
        }
        
        let shipPilot = getPilot(ship: ship)
        
        return Just(shipPilot).eraseToAnyPublisher()
    }
    
    private func getShipV2(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<Result<ShipPilot, Error>, Never>
    {
        global_os_log("CacheService.getShip")
        
        /// Error conditions:
        /// - Ship not found
        /// .success(Ship) or .failure(CacheError.FactoryFailure("..."))
        func getShipFromCache() -> Result<Ship, Error> {
            func getShipFromFile(shipKey: ShipKey) -> Result<Ship, Error> {
                global_os_log("CacheService.getShipFromCache.getShipFromFile", shipKey.description)
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                if shipJSON.isEmpty {
                    return .failure(CacheError.FactoryFailure("Ship not found: \(squadPilot.ship) in \(squad.faction)"))
                }
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                return .success(ship)
            }
            
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            global_os_log("CacheService.getShip.getShipFromCache", shipKey.description)
            
            return shipCache.getValue(key: shipKey, factory: getShipFromFile(shipKey:))
        }
            
        /// Error conditions:
        /// - Upgrade not found
        func getPilot(ship: Ship) -> ShipPilot {
            func getUpgradesFromCache() -> [Upgrade] {
                func getUpgrade(key: UpgradeKey) -> Upgrade? {
                    /// Get upgrade from JSON
                    global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade: \(key)")
                    let upgrades = upgradeCache.getValue(key: key.category, factory: UpgradeUtility.getUpgrades(upgradeCategory:))
                    
                    guard let ret = upgrades.filter({ $0.xws == key.xws }).first else {
                        global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade", "Upgrade Not Found")
                        return nil
                    }
                    
                    return ret
                }
                
                if let upgradeKeys = squadPilot.upgrades?.allUpgradeKeys {
                    return upgradeKeys.compactMap{ key -> Upgrade? in
                        getUpgrade(key: key)
                    }
                }
                
                return []
            }
            
            global_os_log("CacheService.getShip.getPilot")
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            allUpgrades = getUpgradesFromCache()
            
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)
        }
        
        func buildReturn(_ shipPilotResult: Result<ShipPilot, Error>) -> AnyPublisher<Result<ShipPilot, Error>, Never>
        {
            /// Using CombineExt.mapToResult()
            shipPilotResult.publisher.mapToResult()
        }
        
        /// I would like something like:
        /// let x : Result<ShipPilot, Error> = getShipFromCache().map(getPilot(ship:))
        /// switch(x) {
        ///     case .success(let ship): return Just(ship).eraseToAnyPublisher()
        ///     case .failure(_): return Empty().eraseToAnyPublisher()
        /// }
        let shipResult = getShipFromCache()
        
        let shipPilotResult: Result<ShipPilot, Error> = shipResult.map{
            ship -> ShipPilot in
            getPilot(ship: ship)
        }
        
        return buildReturn(shipPilotResult)
    }
}

struct ShipKey: CustomStringConvertible, Hashable {
    // faction xws: "galacticempire"
    let faction: String
    
    // ship xws: "tielnfighter"
    let xws: String
    
    var description: String {
        return "\(faction).\(xws)"
    }
}

struct UpgradeKey : CustomStringConvertible, Hashable {
    let category : String
    let xws: String
    
    var description: String {
        return "\(category).\(xws)"
    }
}
