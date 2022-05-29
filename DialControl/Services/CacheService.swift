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
    func getShip(key: ShipFactionCacheKey) -> Ship?
    func setShip(key: ShipFactionCacheKey, value: Ship)
}

class Cache<Key: Hashable & CustomStringConvertible, Value> {
    private var store = [Key: Value]()
    
    func getValue(key: Key) -> Value? {
        guard let value = store[key] else { return nil }
        return value
    }
    
    func setValue(key: Key, value: Value) {
        store[key] = value
    }

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
                    // FIXME : return an error...
                    return value
            }
        }
    }
}

typealias ShipPilotResult = Result<ShipPilot, Error>
typealias ShipResult = Result<Ship, Error>

/// <#Description#>
class CacheService : CacheServiceProtocol {
    private var shipCache = Cache<ShipKey, Ship>()
    private var upgradeCache = Cache<String, [Upgrade]>()
    private var pilotCache = Cache<PilotKey, Ship>()
    private var shipFactionCache = Cache<ShipFactionCacheKey, Ship>()
    
    enum CacheError : Error {
        case FactoryFailure(String)
    }
    
    func getShip(key: ShipFactionCacheKey) -> Ship? {
        shipFactionCache.getValue(key: key)
    }
    
    func setShip(key: ShipFactionCacheKey, value: Ship) {
        shipFactionCache.setValue(key: key, value: value)
    }
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never> {
        measure("Performance", name: "CacheService.getShip(...).getShipV1(...)") {
            getShipV1(squad: squad, squadPilot: squadPilot, pilotState: pilotState)
        }
    }
    
    private func getShipV1(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheService.getShipV1")
        
        func getShipFromCache() -> Ship? {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheService.getShipFromCache.getShipFromFile", shipKey.description)
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                
                return ship
            }
            
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            global_os_log("CacheService.getShip.getShipFromCache", shipKey.description)
            
            return shipCache.getValue(key: shipKey, factory: getShipFromFile(shipKey:))
        }
            
        func getPilot(ship: inout Ship) -> ShipPilot {
            func getUpgradesFromCache() -> [Upgrade] {
                func getUpgrade(key: UpgradeKey) -> Upgrade? {
                    /// Get upgrade from JSON
                    global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade: \(key)")
                    let upgrades = upgradeCache.getValue(key: key.category, factory: UpgradeUtility.getUpgrades(upgradeCategory:))
                    
                    guard let ret = upgrades.filter({ $0.xws == key.xws }).first else {
                    global_os_log("getPilotV2.getUpgradesFromCache.getUpgrade","\(key) Upgrade Not Found")
                        return nil
                    }
                    
                    return ret
                }
                
                global_os_log("CacheService.getShip.getPilot", squadPilot.id )
                
                if let upgradeKeys = squadPilot.upgrades?.allUpgradeKeys {
                    global_os_log("getPilot(ship:) upgradeKeys.count = \(upgradeKeys.count)")
                    return upgradeKeys.compactMap(getUpgrade)
                }
                
                return []
            }
            
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            allUpgrades = getUpgradesFromCache()
            
            let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
            
            ship.pilots.removeAll()
            ship.pilots.append(foundPilots)
            
            // Why not cache the ShipPilot since we are also caching the Ship
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)
        }
        
        let ship = measure("Performance", name: "CacheService.getShipV1(...).getShipFromCache()") { getShipFromCache() }
        
        guard var ship = ship else {
            return Empty().eraseToAnyPublisher()
        }
        
        let shipPilot = measure("Performance", name: "CacheService.getShipV1(...).getPilot()") {
            return getPilot(ship: &ship)
        }
        
        global_os_log("CacheService.getShip shipPilot", shipPilot.pilotName)
        
        return Just(shipPilot).eraseToAnyPublisher()
    }
    
    private func getShipV2(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilotResult, Never>
    {
        global_os_log("CacheService.getShip")
        
        /// Error conditions:
        /// - Ship not found
        /// .success(Ship) or .failure(CacheError.FactoryFailure("..."))
        func getShipFromCache() -> ShipResult {
            func getShipFromFile(shipKey: ShipKey) -> ShipResult {
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
        
        func buildReturn(_ shipPilotResult: ShipPilotResult) -> AnyPublisher<Result<ShipPilot, Error>, Never>
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
        
        /// builds a ShipPilotResult from ShipResult
        let shipPilotResult: ShipPilotResult = shipResult.map{
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

struct PilotKey : CustomStringConvertible, Hashable {
    let shipKey: ShipKey
    let pilot: String
    
    init(faction: String, ship: String, pilot: String) {
        self.shipKey = ShipKey(faction: faction, xws: ship)
        self.pilot = pilot
    }
    
    var description: String {
        return "\(shipKey.xws).\(pilot).\(shipKey.faction)"
    }
}

struct UpgradeKey : CustomStringConvertible, Hashable {
    let category : String
    let xws: String
    
    var description: String {
        return "\(category).\(xws)"
    }
}

struct ShipFactionCacheKey: Hashable {
    let shipName: String
    let faction: String
}

extension ShipFactionCacheKey : CustomStringConvertible {
    var description: String {
        return "\(faction).\(shipName)"
    }
}
