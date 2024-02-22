//
//  UpgradeUtility.swift
//  DialControl
//
//  Created by Phil Kirby on 9/17/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

struct UpgradeUtility {
    static func getCategory(upgrade: String) -> String? {
        let x: [String : Array<String>] = UpgradeUtility.buildUpgradesDictionary()
        
        for (key, value) in x {
            if (value.contains(upgrade)) { return key }
        }
        
        return nil
    }
    
    enum UpgradeCategories: String, CaseIterable {
        case astromech
        case cannon
        case cargo
        case command
        case configuration
        case crew
        case device
        case forcepower = "forcepower"
        case gunner
        case hardpoint
        case illicit
        case missile
        case modification
        case sensor
        case tacticalrelay = "tactical-relay"
        case talent
        case team
        case tech
        case title
        case torpedo
        case turret
    }
    
    /*
     talent : ["composure", "daredevil", "elusive"]
     cannons : ["ioncannon", "jammingbeam"}
     */
    static func buildUpgradesDictionary() -> [String: Array<String>] {
        var dict: [String: Array<String>] = [:]
        
        // for every case in UpgradeCategories
            // func getUpgrades(upgradeCategory: String) -> [Upgrade]
        for category in UpgradeCategories.allCases {
            // category.rawValue : upgrades
            let upgrades = UpgradeUtility.getUpgrades(upgradeCategory: category.rawValue).map{ $0.xws }
            dict[category.rawValue] = upgrades
        }
        
        return dict
    }

    /*
     talent : ["composure", "daredevil", "elusive"]
     cannons : ["ioncannon", "jammingbeam"}
     */
    var upgradesByCategory: [String: Array<String>] = [:]

    /*
     composure : talent
     daredevil : talent
     elusive : talent
     ioncannon : cannons
     jammingbeam : cannons
     */
    var upgradesByName: [String: String] = [:]
    
    static func getJSONForUpgrade(forType: String, inDirectory: String) -> String {
        func buildFileName() -> String {
            if forType == "forcepower" {
                return "force-power"
            }
            
            return forType
        }
        
        // Read json from file: forType.json
        let jsonFileName = buildFileName()
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
        
        return upgradeJSON
    }
    
    static func getUpgrades(upgradeCategory: String) -> [Upgrade] {
        let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
    
        let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)

        return upgrades
    }
    
    /// We should refactor this
    /// - The `getUpgrade()` will load the JSON file and serialize it for each upgrade the pilot has
    /// - This means that if a pilot has `proximitymines` & `seismiccharges` then the `device.json`
    ///   File is read from disk & serialized twice; once for `proximitymines` and once for `seismiccharges`.  The `device.json` should be read from disk & serialized one time
    ///   into an `[Upgrade]`
    ///   - Read from disk & seriallize into an `[Upgrade]` once per category `device, configuration`.
    ///   - Store the upgrade array into a dictionary keyed by category name `["device": [Upgrade]]`
    ///
    ///  Takes an input of SquadPilotUpgrade :
    ///  "upgrades":{"talent":["deadeyeshot","marksmanship"],"modification":["shieldupgrade"]}}
    ///  and returns an array of Upgrade types
    ///  [Upgrade(talent), Upgrade(deadeyeshot), Upgrade(marksmanship), Upgrade(shieldupgrade)]
    static func buildAllUpgrades(_ upgrades: SquadPilotUpgrade,
                                 store: MyAppStore? = nil) -> [Upgrade] {
        print("UpgradeUtility.buildAllUpgrades \(upgrades)")
            func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
                let upgrades = getUpgrades(upgradeCategory: upgradeCategory)
                let matches: [Upgrade] = upgrades.filter({ $0.xws == upgradeName })
                
                let upgrade = matches[0]
                
                return upgrade
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

    /// Get all upgrades for each category, convert them to Array<Upgrade> and store in dictionary where key is category
    /// and value in Array<Upgrade>
    ///
    /// returns
    ///   "talent" : [Upgrade(marksmanship), Upgrade(Predator)]
    ///   "forcepower" : [Upgrade(Foresight), Upgrade(Malice), Upgrade(Hate)]
    static func buildCategoryToUpgradesDictionary() -> Dictionary<String, Array<Upgrade>> {
        var ret : Dictionary<String, Array<Upgrade>> = [:]
        
        for upgradeCategory in UpgradeCategories.allCases {
            let upgrades = UpgradeUtility.getUpgrades(upgradeCategory: upgradeCategory.rawValue)
            ret[upgradeCategory.rawValue] = upgrades
        }
        
        return ret
    }
    
    static func getUpgradesForNames(upgradeXWSArray: [String]) -> [Upgrade] {
        func getUpgrade(upgradeXWS: String, categoryToUpgradesDictionary: Dictionary<String, [Upgrade]>) -> Upgrade? {
            /*
             categoryToUpgradesDictionary
             
             key            value
             "talent"       [Upgrade(Predator), Upgrade(Marksmanship)]
             "forcepower"   [Upgrade(Foresight), Upgrade(Hate), Upgrade(Malice)]
             
             categoryToUpgradesDictionary.values
             [
                [Upgrade(Predator), Upgrade(Marksmanship)]
                [Upgrade(Foresight), Upgrade(Hate), Upgrade(Malice)]
             ]
             
             allUpgrades = [Upgrade(Predator), Upgrade(Marksmanship),Upgrade(Foresight), Upgrade(Hate), Upgrade(Malice)]
             */
            let allUpgrades: [Upgrade] = categoryToUpgradesDictionary.values.reduce([], +)
            
            if allUpgrades.count > 0 {
                return allUpgrades
                    .filter{ $0.xws.lowercased() == upgradeXWS.lowercased() }
                    .first
            }
            
            return nil
        }
        
        var categoryToUpgradesDictionary : Dictionary<String, Array<Upgrade>> = [:]
        var ret: [Upgrade] = []
        categoryToUpgradesDictionary = buildCategoryToUpgradesDictionary()
        
        for upgradeXWS in upgradeXWSArray {
            if let upgrade = getUpgrade(upgradeXWS: upgradeXWS, categoryToUpgradesDictionary: categoryToUpgradesDictionary) {
                ret.append(upgrade)
            }
        }
        
        return ret
    }
    
    /*
     input
        upgradeXWSArray = ["marksmanship", "predator", "hate", "afterburners"]
        categoryToUpgradesDictionary =
            "talent" : [Upgrade(marksmanship), Upgrade(Predator)]
            "forcepower" : [Upgrade(Foresight), Upgrade(Malice), Upgrade(Hate)]
     
     returns
        filteredDict = "talent":["marksmanship"],"modification":["afterburners"],"forcepower":["hate"]
     */
    static func getUpgradesDictionary(upgradeXWSArray: [String]) -> Dictionary<String, Array<String>> {
        var ret: [String: Array<String>] = [:]
        var categoryToUpgradesDictionary : Dictionary<String, Array<String>> = [:]
        categoryToUpgradesDictionary = buildUpgradesDictionary()
        
        for upgradeXWS in upgradeXWSArray {
            // iterate over categoryToUpgradesDictionary
            for (key, value) in categoryToUpgradesDictionary {
                // key: "talent" value: [Upgrade(marksmanship), Upgrade(Predator)]
                if value.contains(where: { $0 == upgradeXWS }) {
                    if var newValue = ret[key] {
                        // append upgradeXWS to existing array and set array in dict
                        newValue.append(upgradeXWS)
                        ret[key] = newValue
                    } else {
                        // ret is empty
                        ret[key] = [upgradeXWS]
                    }
                }
            }
            
        }
        return ret
    }
}
