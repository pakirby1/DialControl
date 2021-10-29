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
    func loadData(url: Key) -> AnyPublisher<Data, Error>
}

class CacheUtility<Local: ILocalCacheStore, Remote: IRemoteCacheStore> : ICacheService where Local.Key == Remote.Key
{
    let localStore: Local
    let remoteStore: Remote
    
    func loadData(url: Local.Key) -> AnyPublisher<Data, Error> {
        var localData: Bool = false
        
        // see if the image is in the local store
        return self.localStore
            .loadData(key: url as! Local.Key)
            .map { data in
                print("local data")
                localData = true
                return data as! Remote.RemoteObject
            }
            .catch { error in
                /// If an error was encountered reading from the local store, eat the error and attempt to read from the remote store
                /// we will return a new publisher (Future<Data, Error>) that contains either the data or a remote error
                /// what if we get a 404 Not Found response, it will think it succeeded and will return
                /// the html as the data, so we need to catch the 404 error
                self.remoteStore.loadData(key: url)
            }
            .print()
            .map { result -> Data in
                /// Did the result come from the local or Remote Store??  I can't tell...
                print("Success: \(result)")
                let data = result as! Data
                
                // write to the cache, only if it was sourced from the remoteStore
                if (!localData) {
                    self.localStore.saveData(key: url, value: data as! Local.LocalObject)
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

class CacheService<Ship: ICacheService, Upgrade: ICacheService> {
    let shipCache : Ship
    let upgradeCache: Upgrade
    
    init() {
        self.shipCache = CacheUtility(localStore: LocalCache<ShipKey, Ship>(),
                                      remoteStore: ShipRemoteCache<ShipKey, Ship>()) as! Ship
        self.upgradeCache = CacheUtility(localStore: LocalCache<UpgradeKey, Upgrade>(),
                                         remoteStore: UpgradeRemoteCache<UpgradeKey, Upgrade>()) as! Upgrade
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

