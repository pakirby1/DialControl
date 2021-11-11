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

class CacheUtility<Local: ILocalCacheStore, Remote: IRemoteCacheStore> : ICacheService where Local.Key == Remote.Key, Local.LocalObject == Remote.RemoteObject
{
    let localStore: Local
    let remoteStore: Remote
    
    func loadData(key: Local.Key) -> AnyPublisher<Remote.RemoteObject, Never> {
        var localData: Bool = false
        
        // see if the image is in the local store
        return self.localStore
            .loadDataNew(key: key)
            .print("Store.send CacheUtility.loadData")
            .os_log(message: "Store.send CacheUtility.loadData")
            .flatMap { data -> AnyPublisher<Remote.RemoteObject, Never> in
                if let d = data {
                    global_os_log("Store.send CacheUtility.loadData", "found data")
                    localData = true
                    return Just(d).eraseToAnyPublisher()
                }
                
                return self.remoteStore.loadDataNew(key: key)
            }
            .map { data -> Remote.RemoteObject in
                /// Did the result come from the local or Remote Store??  I can't tell...
                print("Success: \(data)")
                
                // write to the cache, only if it was sourced from the remoteStore
                if (!localData) {
                    self.localStore.saveData(key: key, value: data)
                }
                
                return data
            }
            .os_log(message: "Store.send CacheUtility.loadData")
            .eraseToAnyPublisher()
        
        /*
        return self.localStore
            .loadData(key: key)
            .print("Store.send CacheUtility.loadData")
            .os_log(message: "Store.send CacheUtility.loadData")
            .map { data in
                global_os_log("Store.send CacheUtility.loadData", "found data")
                localData = true
                return data
            }
            .catch { error in
                /// If an error was encountered reading from the local store, eat the error and attempt to read from the remote store
                /// we will return a new publisher (Future<Data, Error>) that contains either the data or a remote error
                /// what if we get a 404 Not Found response, it will think it succeeded and will return
                /// the html as the data, so we need to catch the 404 error
//                global_os_log("Store.send CacheUtility.loadData.catch")
                self.remoteStore.loadData(key: key)
            }
            .map { data -> Remote.RemoteObject in
                /// Did the result come from the local or Remote Store??  I can't tell...
                print("Success: \(data)")
                
                // write to the cache, only if it was sourced from the remoteStore
                if (!localData) {
                    self.localStore.saveData(key: key, value: data)
                }
                
                return data
            }
            .os_log(message: "Store.send CacheUtility.loadData")
            .eraseToAnyPublisher()
        */
    }
    
    init(localStore: Local, remoteStore: Remote) {
        self.localStore = localStore
        self.remoteStore = remoteStore
    }
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
            let shipKey = ShipKey(faction: squad.faction, ship: squadPilot.ship)
            
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


class CacheServiceNew : CacheServiceProtocol {
    private var shipCache = [ShipKey:Ship]()
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheServiceNew.getShip")
        
        func getShipFromCache() -> Ship? {
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
            let shipKey = ShipKey(faction: squad.faction, ship: squadPilot.ship)
            
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
        
        guard let ship = getShipFromCache() else {
            return Empty().eraseToAnyPublisher()
        }
        
        let shipPilot = getPilot(ship: ship)
        
        return Just(shipPilot).eraseToAnyPublisher()
        
//        return Empty().eraseToAnyPublisher()
    }
}

class CacheService<ShipCache: ICacheService, UpgradeCache: ICacheService> : CacheServiceProtocol
{
    private let shipCache : ShipCache
    private let upgradeCache: UpgradeCache
    
    init() {
        self.shipCache = CacheUtility(localStore: LocalCache<ShipKey, Ship>(),
                                      remoteStore: ShipRemoteCache<ShipKey, Ship>()) as! ShipCache
        self.upgradeCache = CacheUtility(localStore: LocalCache<UpgradeKey, Upgrade>(),
                                         remoteStore: UpgradeRemoteCache<UpgradeKey, Upgrade>()) as! UpgradeCache
        global_os_log("CacheService.init()")
    }
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> AnyPublisher<ShipPilot, Never>
    {
        global_os_log("CacheService.getShip", squadPilot.ship)
        
        func getShipPilot() -> ShipPilot {
            var shipJSON: String = ""
            
            print("CacheService.getShip.shipName: \(squadPilot.ship)")
            print("pilotName: \(squadPilot.name)")
            print("faction: \(squad.faction)")
            print("pilotStateId: \(String(describing: pilotState.id))")
            
            /// use CacheService.shipCache property
            /// - NetworkCacheService.loadData(...)
            /// - check if the `Ship` for this ship & faction exists in the cache keyed by (ship xws, faction xws) ShipKey,
            /// - if so return the `Ship`
            /// - This is implemented by LocalCache<>.loadData(...)
            /// - if not...
            ///     - read the JSON from disk
            ///     - serialize the JSON into a `Ship`
            ///     - This is implemented by RemoteCache<>.loadData(...)
            ///  - store the `Ship` in the local cache keyed by (ship xws, faction xws)
            ///     - localCache.save(ShipKey, Ship)
            shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
            
            var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
            
            ship.pilots.removeAll()
            ship.pilots.append(foundPilots)
            
            /// use caching
            /// - check if the `Upgrade` for this upgrade exists in the cache keyed by (upgrade xws
            /// - if so return the `Upgrade`
            /// - if not...
            ///     - read the upgrade category (device.json) JSON from disk
            ///     - serialize the JSON into ???
            ///     - store the `[Upgrades]` in the cache keyed by (category xws)
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
        
        func getShipPilotUsingCache() -> AnyPublisher<ShipPilot, Never> {
            func getUpgrades() -> [Upgrade] {
                var allUpgrades : [Upgrade] = []
                
                if let upgrades = squadPilot.upgrades {
                    allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
                }
                
                return allUpgrades
            }
            
            func getUpgradesFromCache() -> AnyPublisher<[UpgradeCache.Value], Never> {
                
                if let upgrades = squadPilot.upgrades {
                    let allUpgradeKyes = upgrades.allUpgradeKeys
                    let publishers = allUpgradeKyes.map { upgradeCache.loadData(key: $0 as! UpgradeCache.Key) }
                    
                    return Publishers.MergeMany(publishers)
                            .collect()
                            .eraseToAnyPublisher()
                }
                
                return Empty().eraseToAnyPublisher()
            }
            
            func getShipFromCache() -> AnyPublisher<Ship, Never> {
                let shipKey = ShipKey(faction: squad.faction, ship: squadPilot.ship)
                
                let shipStream: AnyPublisher<Ship, Never> = shipCache
                    .loadData(key: shipKey as! ShipCache.Key)
                    .os_log(message: "Store.send getShipFromCache.shipStream.loadData")
                    .print("PAK_Cache.getShipFromCache loadData")
                    .map { value -> Ship in
                        var ship = value as! Ship
                        let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                        
                        ship.pilots.removeAll()
                        ship.pilots.append(foundPilots)
                        
                        return ship
                    }
                    .os_log(message: "Store.send getShipFromCache.shipStream.map")
                    .eraseToAnyPublisher()
                
                return shipStream
            }
            
            let shipStream = getShipFromCache()
            let upgradesStream = getUpgradesFromCache()
            
            let shipPilotStream = Publishers.CombineLatest(shipStream, upgradesStream).map { shipAndUpgrades -> ShipPilot in
                let ship = shipAndUpgrades.0
                let upgrades = shipAndUpgrades.1 as! [Upgrade]
                let shipPilot = ShipPilot(ship: ship, upgrades: upgrades, points: squadPilot.points, pilotState: pilotState)
                return shipPilot
            }.eraseToAnyPublisher()
            
//            let shipPilotStream = shipStream
//                .map { ship -> ShipPilot in
//                    let upgrades = getUpgrades()
//
//                    return ShipPilot(ship: ship,
//                                     upgrades: upgrades,
//                                     points: squadPilot.points,
//                                     pilotState: pilotState)
//                }.eraseToAnyPublisher()
            
            
            return shipPilotStream
        }
        
        return getShipPilotUsingCache()
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
    let ship: String
    
    var description: String {
        return "\(faction).\(ship)"
    }
}

class ShipRemoteCache<Key, Value> : IRemoteCacheStore where Key : CustomStringConvertible & Hashable
{
    private var cache = [Key:Value]()
    
    func getShip(key: ShipKey) -> Ship {
        let shipJSON = getJSONFor(ship: key.ship, faction: key.faction)
        
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

