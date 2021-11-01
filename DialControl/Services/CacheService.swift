//
//  CacheService.swift
//  DialControl
//
//  Created by Phil Kirby on 10/29/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine

protocol ICacheService {
    associatedtype Key
    associatedtype Value
    func loadData(key: Key) -> AnyPublisher<Value, Error>
}

class CacheUtility<Local: ILocalCacheStore, Remote: IRemoteCacheStore> : ICacheService where Local.Key == Remote.Key, Local.LocalObject == Remote.RemoteObject
{
    let localStore: Local
    let remoteStore: Remote
    
    func loadData(key: Local.Key) -> AnyPublisher<Remote.RemoteObject, Error> {
        var localData: Bool = false
        
        // see if the image is in the local store
        return self.localStore
            .loadData(key: key)
            .map { data in
                print("local data")
                localData = true
                return data
            }
            .catch { error in
                /// If an error was encountered reading from the local store, eat the error and attempt to read from the remote store
                /// we will return a new publisher (Future<Data, Error>) that contains either the data or a remote error
                /// what if we get a 404 Not Found response, it will think it succeeded and will return
                /// the html as the data, so we need to catch the 404 error
                self.remoteStore.loadData(key: key)
            }
            .print()
            .map { data -> Remote.RemoteObject in
                /// Did the result come from the local or Remote Store??  I can't tell...
                print("Success: \(data)")
                
                // write to the cache, only if it was sourced from the remoteStore
                if (!localData) {
                    self.localStore.saveData(key: key, value: data)
                }
                
                return data
            }
            .print()
            .eraseToAnyPublisher()
    }
    
    init(localStore: Local, remoteStore: Remote) {
        self.localStore = localStore
        self.remoteStore = remoteStore
    }
}

class CacheService<ShipCache: ICacheService, UpgradeCache: ICacheService> {
    let shipCache : ShipCache
    let upgradeCache: UpgradeCache
    
    init() {
        self.shipCache = CacheUtility(localStore: LocalCache<ShipKey, Ship>(),
                                      remoteStore: ShipRemoteCache<ShipKey, Ship>()) as! ShipCache
        self.upgradeCache = CacheUtility(localStore: LocalCache<UpgradeKey, Upgrade>(),
                                         remoteStore: UpgradeRemoteCache<UpgradeKey, Upgrade>()) as! UpgradeCache
    }
    
    func getShip(squad: Squad,
                 squadPilot: SquadPilot,
                 pilotState: PilotState) -> ShipPilot
    {
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
        
        func getShipPilotUsingCache() -> AnyPublisher<ShipPilot, Error> {
            func getUpgrades() -> [Upgrade] {
                var allUpgrades : [Upgrade] = []
                
                if let upgrades = squadPilot.upgrades {
                    allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
                }
                
                return allUpgrades
            }
            
            func getUpgradesFromCache() -> [Upgrade] {
                return []
            }
            
            let shipKey = ShipKey(faction: squad.faction, ship: squadPilot.ship)
            return shipCache
                .loadData(key: shipKey as! ShipCache.Key)
                .map{ value in
                    var ship = value as! Ship
                    let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
                    
                    ship.pilots.removeAll()
                    ship.pilots.append(foundPilots)
                    let upgrades = getUpgrades()
                    
                    return ShipPilot(ship: ship,
                                     upgrades: upgrades,
                                     points: squadPilot.points,
                                     pilotState: pilotState)
                }
                .eraseToAnyPublisher()
        }
        
        return getShipPilot()
    }
}

class LocalCache<Key, Value> : ILocalCacheStore where Key : CustomStringConvertible,Key: Hashable
{
    private var cache = [Key:Value]()
    
    func loadData(key: Key) -> Future<Value, Error> {
        Future<Value, Error> { promise in
            if let keyValue = self.cache.first(where: { tuple -> Bool in
                return tuple.key == key ? true : false
            }) {
                promise(.success(keyValue.value))
            } else {
                promise(.failure(CacheStoreError.cacheMiss(key.description)))
            }
        }
    }
    
    func saveData(key: Key, value: Value) {
        self.cache[key] = value
    }
}

class RemoteCache<Key, Value> : IRemoteCacheStore where Key : CustomStringConvertible & Hashable
{
    private var cache = [Key:Value]()
    
    func loadData(key: Key) -> Future<Value, Error> {
        Future<Value, Error> { promise in
            /// Load from File or Network
            /// - If the key is ShipKey type then global_getShip(....)
            /// - If the key is String type then getAllUpgrades(...)
            if let keyValue = self.cache.first(where: { tuple -> Bool in
                return tuple.key == key ? true : false
            }) {
                promise(.success(keyValue.value))
            } else {
                promise(.failure(CacheStoreError.cacheMiss(key.description)))
            }
        }
    }
}

protocol ILocalCacheStore {
    associatedtype LocalObject
    associatedtype Key
    func loadData(key: Key) -> Future<LocalObject, Error>
    func saveData(key: Key, value: LocalObject)
}

protocol IRemoteCacheStore {
    associatedtype Key
    associatedtype RemoteObject
    func loadData(key: Key) -> Future<RemoteObject, Error>
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
    
    func getShip(ship: ShipKey) -> String? {
        return "test"
    }
    
    func loadData(key: ShipKey) -> Future<Value, Error> {
        Future<Value, Error> { promise in
            /// Load from File or Network
            /// - If the key is ShipKey type then global_getShip(....)
            
            if let ship = self.getShip(ship: key) {
                promise(.success(ship as! Value))
            } else {
                promise(.failure(CacheStoreError.cacheMiss(key.description)))
            }
        }
    }
}

class UpgradeRemoteCache<Key, Value> : IRemoteCacheStore where Key : CustomStringConvertible & Hashable
{
    private var cache = [Key:Value]()
    
    func getUpgrade(key: UpgradeKey) -> String? {
        /// Get upgrade from JSON
        
        return "afterburners"
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
}

struct UpgradeKey : CustomStringConvertible, Hashable {
    let category : String
    let upgrade: String
    
    var description: String {
        return "\(category).upgrade"
    }
}

