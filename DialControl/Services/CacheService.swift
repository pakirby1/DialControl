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

class CacheService : CacheServiceProtocol {
    private var shipCache = CacheNew<ShipKey, Ship>()
    private var upgradeCache = CacheNew<String, [Upgrade]>()
    
    func getShip(squad: Squad,
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
            
            return shipCache.getValue(key: shipKey, factory: getShipFromFile)
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
