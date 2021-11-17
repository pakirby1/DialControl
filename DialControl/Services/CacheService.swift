//
//  CacheService.swift
//  DialControl
//
//  Created by Phil Kirby on 10/29/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine

protocol CacheServiceProtocol {
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
}

protocol ICacheService {
    associatedtype Key
    associatedtype Value
    func loadData(key: Key) -> AnyPublisher<Value, Never>
}

class CacheServiceNewRx : CacheServiceProtocol {
    private var shipCache = [ShipKey:Ship]()
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheServiceNewRx.getShip")
        
        func getShipFromCache() -> AnyPublisher<Ship, Never> {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheServiceNewRx.getShipFromFile shipKey:\(shipKey.description)")
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                // Save to cache
                shipCache[shipKey] = ship
                global_os_log("CacheServiceNewRx.getShipFromFile.shipCache count: \(shipCache.count)")
                
                return ship
            }
            
            global_os_log("CacheServiceNewRx.getShip.getShipFromCache")
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            
            if let ship = shipCache[shipKey] {
                global_os_log("CacheServiceNewRx.getShip.getShipFromCache hit")
                return Just(ship).eraseToAnyPublisher()
            } else {
                global_os_log("CacheServiceNewRx.getShip.getShipFromCache miss")
                return Just(getShipFromFile(shipKey: shipKey)).eraseToAnyPublisher()
            }
        }
        
        func getPilot(ship: Ship) -> AnyPublisher<ShipPilot, Never> {
            global_os_log("CacheServiceNewRx.getShip.getPilot")
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            if let upgrades = squadPilot.upgrades {
                allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
            }
            
            global_os_log("CacheServiceNewRx.getShip.getPilot allUpgrades: \(allUpgrades)")
            
            return Just(ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)).eraseToAnyPublisher()
        }
        
        return getShipFromCache()
            .os_log(message: "CacheServiceNewRx.getShipFromCache returns")
            .flatMap{ ship -> AnyPublisher<ShipPilot, Never> in
                getPilot(ship: ship)
                    .eraseToAnyPublisher()
            }
            .os_log(message: "CacheServiceNewRx.getShip returns")
            .eraseToAnyPublisher()
    }
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
}

class CacheServiceV2 : CacheServiceProtocol {
    private var shipCache = CacheNew<ShipKey, Ship>()
    private var upgradeCache = CacheNew<String, [Upgrade]>()
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheServiceV2.getShip")
        
        func getShipFromCache() -> Ship? {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheServiceV2.getShipFromCache.getShipFromFile", shipKey.description)
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                return ship
            }
            
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            global_os_log("CacheServiceV2.getShip.getShipFromCache", shipKey.description)
            
            return shipCache.getValue(key: shipKey, factory: getShipFromFile)
        }
            
        func getPilot(ship: Ship) -> ShipPilot {
            func getPilotV1(ship: Ship) -> ShipPilot {
                global_os_log("CacheServiceV2.getShip.getPilot")
                var allUpgrades : [Upgrade] = []
                
                // Add the upgrades from SquadPilot.upgrades by iterating over the
                // UpgradeCardEnum cases and calling getUpgrade
                if let upgrades = squadPilot.upgrades {
                    allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
                }
                
                return ShipPilot(ship: ship,
                                 upgrades: allUpgrades,
                                 points: squadPilot.points,
                                 pilotState: pilotState)
            }
            
            func getPilotV2(ship: Ship) -> ShipPilot {
                func getUpgradesFromCache() -> [Upgrade] {
                    func getUpgrade(key: UpgradeKey) -> Upgrade? {
                        /// Get upgrade from JSON
                        logMessage("getPilotV2.getUpgradesFromCache.getUpgrade: \(key)")
                        let upgrades = upgradeCache.getValue(key: key.category, factory: UpgradeUtility.getUpgrades(upgradeCategory:))
                        
                        return upgrades.filter{ $0.xws == key.upgrade }.first
                    }
                    
                    if let upgradeKeys = squadPilot.upgrades?.allUpgradeKeys {
                        return upgradeKeys.compactMap(getUpgrade)
                    }
                    
                    return []
                }
                
                global_os_log("CacheServiceV2.getShip.getPilot")
                var allUpgrades : [Upgrade] = []
                
                // Add the upgrades from SquadPilot.upgrades by iterating over the
                // UpgradeCardEnum cases and calling getUpgrade
                allUpgrades = getUpgradesFromCache()
                
                return ShipPilot(ship: ship,
                                 upgrades: allUpgrades,
                                 points: squadPilot.points,
                                 pilotState: pilotState)
            }
            
            return getPilotV2(ship: ship)
        }
        
        guard let ship = getShipFromCache() else {
            return Empty().eraseToAnyPublisher()
        }
        
        let shipPilot = getPilot(ship: ship)
        
        return Just(shipPilot).eraseToAnyPublisher()
    }
}


class CacheServiceNew : CacheServiceProtocol {
    private var shipCache = [ShipKey:Ship]()
    private var cache = CacheNew<ShipKey, Ship>()
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheServiceNew.getShip")
        
        func getShipFromCacheNew() -> Ship? {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheServiceNew.getShipFromFile")
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                return ship
            }
            
            global_os_log("CacheServiceNew.getShip.getShipFromCacheNew")
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            
            return cache.getValue(key: shipKey, factory: getShipFromFile)
        }
        
        func getShipFromCacheOld() -> Ship? {
            func getShipFromFile(shipKey: ShipKey) -> Ship {
                global_os_log("CacheServiceNew.getShipFromFile")
                var shipJSON: String = ""
                
                shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
                
                var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                
                ship.pilots.removeAll()
                ship.pilots.append(foundPilots)
                
                // Save to cache
                shipCache[shipKey] = ship
                global_os_log("CacheServiceNew.getShipFromFile.shipCache count: \(shipCache.count)")
                
                return ship
            }
            
            global_os_log("CacheServiceNew.getShip.getShipFromCache")
            let shipKey = ShipKey(faction: squad.faction, xws: squadPilot.ship)
            
            if let ship = shipCache[shipKey] {
                global_os_log("CacheServiceNew.getShip.getShipFromCache hit")
                return ship
            } else {
                global_os_log("CacheServiceNew.getShip.getShipFromCache miss")
                return getShipFromFile(shipKey: shipKey)
            }
        }
        
        func getPilot(ship: Ship) -> ShipPilot {
            global_os_log("CacheServiceNew.getShip.getPilot")
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            if let upgrades = squadPilot.upgrades {
                allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
            }
            
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)
        }
        
        guard let ship = getShipFromCacheNew() else {
            return Empty().eraseToAnyPublisher()
        }
        
        let shipPilot = getPilot(ship: ship)
        
        return Just(shipPilot).eraseToAnyPublisher()
        
//        return Empty().eraseToAnyPublisher()
    }
}


class LocalCache<Key, Value> : ILocalCacheStore where Key : CustomStringConvertible,Key: Hashable
{
    private var cache = [String:Value]()
    
    /*
     loadData(key).map { result -> ??? in
        switch(result) {
            case .success(value):
                return value
            case .failure(Error)
                return RemoteCache.loadData(???)
        }
     }
        
     */
    func loadData(key: Key) -> AnyPublisher<Value?, Error> {
        Result<Value?, Error> {
            if let keyValue = self.cache[key.description] {
                return keyValue
            } else {
                return nil
            }
        }
        .publisher
        .eraseToAnyPublisher()
    }

    func loadDataNew(key: Key) -> AnyPublisher<Value?, Never> {
        if let value = self.cache[key.description] {
            global_os_log("LocalCache.loadData hit: \(key.description)")
            return Just(value).eraseToAnyPublisher()
        } else {
            global_os_log("LocalCache.loadData miss: \(key.description)")
            return Just(nil).eraseToAnyPublisher()
        }
    }
    
    func loadData(key: Key) -> Future<Value, Error> {
//        self.cache.enumerated().forEach { tuple in
//            logMessage("PAK_Cache.loadData self.cache \(tuple.element.key.description)")
//        }
        
        return Future<Value, Error> { promise in
            if key.description == "talent.disciplined" {
                logMessage("PAK_Cache.loadData looking for \(key) in \(self.cache[key.description])")
            }
            
            global_os_log("LocalCache.loadData", "cache count: \(self.cache.count)")
            if let keyValue = self.cache[key.description] {
                global_os_log("LocalCache.loadData hit: \(key.description)")
                promise(.success(keyValue))
            } else {
                global_os_log("LocalCache.loadData miss: \(key.description)")
                promise(.failure(CacheStoreError.cacheMiss(key.description)))
            }
        }
    }
    
    func saveData(key: Key, value: Value) {
        if key.description == "talent.disciplined" {
            logMessage("PAK_Cache.saveData \(key.description)")
        }
        
        self.cache[key.description] = value
        global_os_log("LocalCache.saveData added: \(key.description)")
    }
}

protocol ILocalCacheStore {
    associatedtype LocalObject
    associatedtype Key
    func loadData(key: Key) -> Future<LocalObject, Error>
    func saveData(key: Key, value: LocalObject)
    func loadDataNew(key: Key) -> AnyPublisher<LocalObject?, Never>
}

protocol IRemoteCacheStore {
    associatedtype Key
    associatedtype RemoteObject
    func loadData(key: Key) -> Future<RemoteObject, Error>
    func loadDataNew(key: Key) -> AnyPublisher<RemoteObject, Never>
}

enum CacheStoreError : Error {
    case cacheMiss(String)
    case remoteMiss(String)
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

class ShipRemoteCache<Key, Value> : IRemoteCacheStore where Key : CustomStringConvertible & Hashable
{
    private var cache = [Key:Value]()
    
    func getShip(key: ShipKey) -> Ship {
        let shipJSON = getJSONFor(ship: key.xws, faction: key.faction)
        
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        global_os_log("ShipRemoteCache.getShip", shipJSON)
        
        return ship
    }
    
    func loadData(key: ShipKey) -> Future<Value, Error> {
        Future<Value, Error> { promise in
            /// Load from File or Network
            /// - If the key is ShipKey type then global_getShip(....)
            
            let ship = self.getShip(key: key)
            promise(.success(ship as! Value))
        }
    }
    
    func loadDataNew(key: ShipKey) -> AnyPublisher<Value, Never> {
        let ship = self.getShip(key: key)
        return Just(ship as! Value).eraseToAnyPublisher()
    }
}

class UpgradeRemoteCache<Key, Value> : IRemoteCacheStore where Key : CustomStringConvertible & Hashable
{
    private var cache = [Key:Value]()
    
    func getUpgrade(key: UpgradeKey) -> Upgrade? {
        /// Get upgrade from JSON
        logMessage("PAK_Cache.getUpgrade: \(key)")
        let upgrades = UpgradeUtility.getUpgrades(upgradeCategory: key.category)
        
        return upgrades.filter{ $0.xws == key.upgrade }.first
    }
    
    func loadData(key: UpgradeKey) -> Future<Value, Error> {
        Future<Value, Error> { promise in
            /// Load from File or Network
            if let upgrade = self.getUpgrade(key: key) {
                promise(.success(upgrade as! Value))
            } else {
                promise(.failure(CacheStoreError.cacheMiss(key.description)))
            }
        }
    }
    
    func loadDataNew(key: UpgradeKey) -> AnyPublisher<Value, Never> {
        if let upgrade = self.getUpgrade(key: key) {
            return Just(upgrade as! Value).eraseToAnyPublisher()
        } else {
            return Empty().eraseToAnyPublisher()
        }
    }
}

struct UpgradeKey : CustomStringConvertible, Hashable {
    let category : String
    let upgrade: String
    
    var description: String {
        return "\(category).\(upgrade)"
    }
}

