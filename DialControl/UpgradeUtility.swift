//
//  UpgradeUtility.swift
//  DialControl
//
//  Created by Phil Kirby on 9/17/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

struct UpgradeUtility {
    /// We should refactor this
    /// - The `getUpgrade()` will load the JSON file and serialize it for each upgrade the pilot has
    /// - This means that if a pilot has `proximitymines` & `seismiccharges` then the `device.json`
    ///   File is read from disk & serialized twice; once for `proximitymines` and once for `seismiccharges`.  The `device.json` should be read from disk & serialized one time
    ///   into an `[Upgrade]`
    ///   - Read from disk & seriallize into an `[Upgrade]` once per category `device, configuration`.
    ///   - Store the upgrade array into a dictionary keyed by category name `["device": [Upgrade]]`
    ///
    static func buildAllUpgrades(_ upgrades: SquadPilotUpgrade,
                                 store: MyAppStore? = nil) -> [Upgrade] {
        print("UpgradeUtility.buildAllUpgrades \(upgrades)")
        
            func getJSONForUpgrade(forType: String, inDirectory: String) -> String {
                // Read json from file: forType.json
                let jsonFileName = "\(forType)"
                var upgradeJSON = ""
                
                if let path = Bundle.main.path(forResource: jsonFileName,
                                               ofType: "json",
                                               inDirectory: inDirectory)
                {
                    print("path: \(path)")
                    
                    do {
                        upgradeJSON = try String(contentsOfFile: path)
                        print("upgradeJSON: \(upgradeJSON)")
                    } catch {
                        print("error reading from \(path)")
                    }
                }
                
                //            return modificationsUpgradesJSON
                return upgradeJSON
            }
            
            // getUpgrade(upgradeCategory: "device", upgradeName: "thermaldetonators")
            func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
//                let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
//
//                let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
               
                let upgrades = getUpgrades(upgradeCategory: upgradeCategory)
                let matches: [Upgrade] = upgrades.filter({ $0.xws == upgradeName })
                
                let upgrade = matches[0]
                
                return upgrade
            }
        
            func getUpgrades(upgradeCategory: String) -> [Upgrade] {
//                return getUpgrades_old(upgradeCategory: upgradeCategory)
                return getUpgrades_new(upgradeCategory: upgradeCategory)
            }
        
            func getUpgrades_old(upgradeCategory: String) -> [Upgrade] {
                let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
                
                let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)

                return upgrades
            }
        
            func getUpgrades_new(upgradeCategory: String) -> [Upgrade] {
                func getUpgradesFromCache(upgradeCategory: String) -> [Upgrade]? {
                    guard let upgrades = store?.state.upgrades.upgrades[upgradeCategory] else {
                        return nil
                    }
                    
                    guard !upgrades.isEmpty else {
                        return nil
                    }
                    
                    return upgrades
                }
                
                func setUpgradesInCache(upgradeCategory: String, upgrades: [Upgrade]) {
                    guard let store = store else { return }
                    
                    logMessage("UpgradeUtility setUpgradesInCache(\(upgradeCategory))")
                    store.state.upgrades.upgrades[upgradeCategory] = upgrades
                }
                
                func getUpgradesFromJSON(upgradeCategory: String) -> [Upgrade] {
                    let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
                    
                    let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
                    
                    setUpgradesInCache(upgradeCategory: upgradeCategory, upgrades: upgrades)
                    
                    return upgrades
                }
                
                
                if let upgrades = getUpgradesFromCache(upgradeCategory: upgradeCategory) {
                    logMessage("UpgradeUtility getUpgradesFromCache(\(upgradeCategory))")
                    return upgrades
                } else {
                    logMessage("UpgradeUtility getUpgradesFromJSON(\(upgradeCategory))")

                    return getUpgradesFromJSON(upgradeCategory: upgradeCategory)
                }
            }
        
            func buildUpgradeDictionary() {
                let allAstromechs : [Upgrade] = getUpgrades(upgradeCategory: "astromech")
                var dict: [String: [Upgrade]] = [:]
                
                dict["astromech"] = allAstromechs
                
                /// upgrades.astromechs : [String]
//                let astromechs: [Upgrade] = upgrades
//                    .astromechs
//                    .compactMap { astromech in
//                        let x: [Upgrade]? = dict["astromech"]?.filter { $0.name == astromech}
//
//                        guard let u = x else {
//                            return
//                        }
//                    }
            }
        
            var allUpgrades : [Upgrade] = []
            
            
        
            let astromechs : [Upgrade] = upgrades
                .astromechs
                .map{ getUpgrade(upgradeCategory: "astromech", upgradeName: $0) }
            
            let cannons : [Upgrade] = upgrades
                .cannons
                .map{ getUpgrade(upgradeCategory: "cannon", upgradeName: $0) }
            
            let cargos : [Upgrade] = upgrades
                .cargos
                .map{ getUpgrade(upgradeCategory: "cargo", upgradeName: $0) }
            
            let commands : [Upgrade] = upgrades
                .commands
                .map{ getUpgrade(upgradeCategory: "command", upgradeName: $0) }
            
            let configurations : [Upgrade] = upgrades
                .configurations
                .map{ getUpgrade(upgradeCategory: "configuration", upgradeName: $0) }
            
            let crews : [Upgrade] = upgrades
                .crews
                .map{ getUpgrade(upgradeCategory: "crew", upgradeName: $0) }
            
            let devices : [Upgrade] = upgrades
                .devices
                .map{ getUpgrade(upgradeCategory: "device", upgradeName: $0) }
            
            let forcepowers : [Upgrade] = upgrades
                .forcepowers
                .map{
                    getUpgrade(upgradeCategory: "force-power", upgradeName: $0)
                }
            
            let gunners : [Upgrade] = upgrades
                .gunners
                .map{ getUpgrade(upgradeCategory: "gunner", upgradeName: $0) }
            
            let hardpoints : [Upgrade] = upgrades
                .hardpoints
                .map{ getUpgrade(upgradeCategory: "hardpoint", upgradeName: $0) }
            
            let illicits : [Upgrade] = upgrades
                .illicits
                .map{ getUpgrade(upgradeCategory: "illicit", upgradeName: $0) }
            
            let missiles : [Upgrade] = upgrades
                .missiles
                .map{ getUpgrade(upgradeCategory: "missile", upgradeName: $0) }
            
            let modifications : [Upgrade] = upgrades
                .modifications
                .map{ getUpgrade(upgradeCategory: "modification", upgradeName: $0) }
            
            let sensors : [Upgrade] = upgrades
                .sensors
                .map{ getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
            
            let tacticalrelays : [Upgrade] = upgrades
                .tacticalrelays
                .map{ getUpgrade(upgradeCategory: "tactical-relay", upgradeName: $0) }
            
            let talents : [Upgrade] = upgrades
                .talents
                .map{ getUpgrade(upgradeCategory: "talent", upgradeName: $0) }
            
            let teams : [Upgrade] = upgrades
                .teams
                .map{ getUpgrade(upgradeCategory: "team", upgradeName: $0) }
            
            let techs : [Upgrade] = upgrades
                .techs
                .map{ getUpgrade(upgradeCategory: "tech", upgradeName: $0) }
            
            let titles : [Upgrade] = upgrades
                .titles
                .map{ getUpgrade(upgradeCategory: "title", upgradeName: $0) }
            
            let torpedos : [Upgrade] = upgrades
                .torpedos
                .map{ getUpgrade(upgradeCategory: "torpedo", upgradeName: $0) }
            
            let turrets : [Upgrade] = upgrades
                .turrets
                .map{ getUpgrade(upgradeCategory: "turret", upgradeName: $0) }
            
            allUpgrades += astromechs
            allUpgrades += cannons
            allUpgrades += cargos
            allUpgrades += commands
            allUpgrades += configurations
            allUpgrades += crews
            allUpgrades += devices
            allUpgrades += forcepowers
            allUpgrades += gunners
            allUpgrades += hardpoints
            allUpgrades += illicits
            allUpgrades += missiles
            allUpgrades += modifications
            allUpgrades += sensors
            allUpgrades += tacticalrelays
            allUpgrades += talents
            allUpgrades += teams
            allUpgrades += techs
            allUpgrades += titles
            allUpgrades += torpedos
            allUpgrades += turrets

            return allUpgrades
        }

    static func buildAllUpgrades_throws(_ upgrades: SquadPilotUpgrade) throws -> [Upgrade] {
        func getJSONForUpgrade(forType: String, inDirectory: String) throws -> String {
            // Read json from file: forType.json
            let jsonFileName = "\(forType)"
            var upgradeJSON = ""
            
            if let path = Bundle.main.path(forResource: jsonFileName,
                                           ofType: "json",
                                           inDirectory: inDirectory)
            {
                print("path: \(path)")
                
                do {
                    upgradeJSON = try String(contentsOfFile: path)
                    print("upgradeJSON: \(upgradeJSON)")
                } catch {
                    throw JSONSerializationError.bundlePathNotFound("\(path)")
                }
            }
            
            //            return modificationsUpgradesJSON
            return upgradeJSON
        }
        
        func getUpgrade(upgradeCategory: String, upgradeName: String) throws -> Upgrade {
            do {
                
                let jsonString = try getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
                
                let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
                
                let matches: [Upgrade] = upgrades.filter({ $0.xws == upgradeName })
                
                let upgrade = matches[0]
                
                return upgrade
                
            }
            catch {
                throw error
            }
        }
        
        do {
            var allUpgrades : [Upgrade] = []
            
            let astromechs : [Upgrade] = try upgrades
                .astromechs
                .map{ try getUpgrade(upgradeCategory: "astromech", upgradeName: $0) }
            
            let cannons : [Upgrade] = try upgrades
                .cannons
                .map{ try getUpgrade(upgradeCategory: "cannon", upgradeName: $0) }
            
            let cargos : [Upgrade] = try upgrades
                .cargos
                .map{ try getUpgrade(upgradeCategory: "cargo", upgradeName: $0) }
            
            let commands : [Upgrade] = try upgrades
                .commands
                .map{ try getUpgrade(upgradeCategory: "command", upgradeName: $0) }
            
            let configurations : [Upgrade] = try upgrades
                .configurations
                .map{ try getUpgrade(upgradeCategory: "configuration", upgradeName: $0) }
            
            let crews : [Upgrade] = try upgrades
                .crews
                .map{ try getUpgrade(upgradeCategory: "crew", upgradeName: $0) }
            
            let devices : [Upgrade] = try upgrades
                .devices
                .map{ try getUpgrade(upgradeCategory: "device", upgradeName: $0) }
            
            let forcepowers : [Upgrade] = try upgrades
                .forcepowers
                .map{
                    try getUpgrade(upgradeCategory: "force-power", upgradeName: $0)
            }
            
            let gunners : [Upgrade] = try upgrades
                .gunners
                .map{ try getUpgrade(upgradeCategory: "gunner", upgradeName: $0) }
            
            let hardpoints : [Upgrade] = try upgrades
                .hardpoints
                .map{ try getUpgrade(upgradeCategory: "hardpoint", upgradeName: $0) }
            
            let illicits : [Upgrade] = try upgrades
                .illicits
                .map{ try getUpgrade(upgradeCategory: "illicit", upgradeName: $0) }
            
            let missiles : [Upgrade] = try upgrades
                .missiles
                .map{ try getUpgrade(upgradeCategory: "missile", upgradeName: $0) }
            
            let modifications : [Upgrade] = try upgrades
                .modifications
                .map{ try getUpgrade(upgradeCategory: "modification", upgradeName: $0) }
            
            let sensors : [Upgrade] = try upgrades
                .sensors
                .map{ try getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
            
            let tacticalrelays : [Upgrade] = try upgrades
                .tacticalrelays
                .map{ try getUpgrade(upgradeCategory: "tactical-relay", upgradeName: $0) }
            
            let talents : [Upgrade] = try upgrades
                .talents
                .map{ try getUpgrade(upgradeCategory: "talent", upgradeName: $0) }
            
            let teams : [Upgrade] = try upgrades
                .teams
                .map{ try getUpgrade(upgradeCategory: "team", upgradeName: $0) }
            
            let techs : [Upgrade] = try upgrades
                .techs
                .map{ try getUpgrade(upgradeCategory: "tech", upgradeName: $0) }
            
            let titles : [Upgrade] = try upgrades
                .titles
                .map{ try getUpgrade(upgradeCategory: "title", upgradeName: $0) }
            
            let torpedos : [Upgrade] = try upgrades
                .torpedos
                .map{ try getUpgrade(upgradeCategory: "torpedo", upgradeName: $0) }
            
            let turrets : [Upgrade] = try upgrades
                .turrets
                .map{ try getUpgrade(upgradeCategory: "turret", upgradeName: $0) }
            
            allUpgrades += astromechs
            allUpgrades += cannons
            allUpgrades += cargos
            allUpgrades += commands
            allUpgrades += configurations
            allUpgrades += crews
            allUpgrades += devices
            allUpgrades += forcepowers
            allUpgrades += gunners
            allUpgrades += hardpoints
            allUpgrades += illicits
            allUpgrades += missiles
            allUpgrades += modifications
            allUpgrades += sensors
            allUpgrades += tacticalrelays
            allUpgrades += talents
            allUpgrades += teams
            allUpgrades += techs
            allUpgrades += titles
            allUpgrades += torpedos
            allUpgrades += turrets
            
            return allUpgrades
        }
        catch{
            throw error
        }
    }
}
