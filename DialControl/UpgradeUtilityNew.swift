//
//  UpgradeUtilityNew.swift
//  DialControl
//
//  Created by Phil Kirby on 1/31/24.
//  Copyright © 2024 SoftDesk. All rights reserved.
//

import Foundation

class UpgradeUtilityNew {
    init() {
        upgradesData = UpgradesData()
    }
    
    var upgradesData : UpgradesData
    
    static func getCategory(upgrade: String) -> String? {
        func buildUpgradesDictionary() -> [String: Array<String>] {
            var dict: [String: Array<String>] = [:]
            
            // for every case in UpgradeCategories
                // func getUpgrades(upgradeCategory: String) -> [Upgrade]
            for category in UpgradesData.UpgradeCategories.allCases {
                // category.rawValue : upgrades
                let upgrades = UpgradeUtility.getUpgrades(upgradeCategory: category.rawValue).map{ $0.xws }
                dict[category.rawValue] = upgrades
            }
            
            return dict
        }
        
        let x: [String : Array<String>] = UpgradeUtility.buildUpgradesDictionary()
        
        for (key, value) in x {
            if (value.contains(upgrade)) { return key }
        }
        
        return nil
    }
    
    /*
     Load the JSON file for the upgradeCategory into an array of Upgrade objects
     */
    static func getUpgrades(upgradeCategory: String) -> [Upgrade] {
        func getJSONForUpgrade(forType: String, inDirectory: String) -> String {
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
        
        let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
    
        let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)

        return upgrades
    }
    
    /// REMOVE
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
    
    ///  Takes an input of SquadPilotUpgrade :
    ///  "upgrades":{"talent":["deadeyeshot","marksmanship"],"modification":["shieldupgrade"]}}
    ///  and returns an array of Upgrade types
    ///  [Upgrade(talent), Upgrade(deadeyeshot), Upgrade(marksmanship), Upgrade(shieldupgrade)]
    func getUpgradesForSquadPilotUpgrade(_ upgrades: SquadPilotUpgrade,
                                    store: MyAppStore? = nil) -> [Upgrade] {
        return getSquadPilotUpgradesFromUpgradesData(upgrades)
    }
    
    /// Takes an input of standardLoadout upgrade names
    /// ["feedbackping", "plasmatorpedoes", "protonbombs"]
    /// and returns an array of Upgrade types
    /// [Upgrade("feedbackping"), Upgrade("plasmatorpedoes"), Upgrade("protonbombs")]
    func getUpgradesForNames(upgradeNames: [String]) -> [Upgrade] {
        var ret: [Upgrade] = []
        
        for upgradeName in upgradeNames {
            if let upgrade = upgradesData.getUpgrade(upgradeName: upgradeName) {
                ret.append(upgrade)
            }
        }
        
        return ret
    }
    
    private func getSquadPilotUpgradesFromUpgradesData(_ upgrades: SquadPilotUpgrade) -> [Upgrade] {
        func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
            let upgrades = upgradesData.getUpgrades(upgradeCategory: upgradeCategory)
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
}


class UpgradesData {
    init() {
        buildCategoryToUpgradesDictionary()
    }
    
    /*
     force  -> [Upgrade(foresight), Upgrade(malice), Upgrade(hate)]
     talent -> [Upgrade(truegrit), Upgrade(predator), Upgrade(feedbackping)]
     */
    var categoryToUpgradesDictionary : Dictionary<String, Array<Upgrade>> = [:]
    
    /// Get all upgrades for each category, convert them to Array<Upgrade> and store in dictionary where key is category
    /// and value in Array<Upgrade>
    ///
    func buildCategoryToUpgradesDictionary() {
        for upgradeCategory in UpgradeCategories.allCases {
            let upgrades = UpgradeUtility.getUpgrades(upgradeCategory: upgradeCategory.rawValue)
            categoryToUpgradesDictionary[upgradeCategory.rawValue] = upgrades
        }
    }
    
    /// Get an array of Upgrade by category
    func getUpgrades(upgradeCategory: String) -> Array<Upgrade> {
        return categoryToUpgradesDictionary[upgradeCategory] ?? []
    }
    
    /// Get an Upgrade by name
    func getUpgrade(upgradeName: String) -> Upgrade? {
        let filteredUpgrades: Dictionary<String, [Upgrade]> = categoryToUpgradesDictionary.mapValues {
            // $0 = [Upgrade(foresight), Upgrade(malice), Upgrade(hate)]
            $0.filter {
                // $0 = Upgrade
                $0.name == upgradeName
            }
        }
        
        // if upgradeName = "foresight"
        // filteredUpgrades = ["force" : [Upgrade("foresight")]]
        // filteredUpgrades.key = "force"
        // filteredUpgrades.value = [Upgrade("foresight")] or nil
        if filteredUpgrades.count > 0 {
            if let value = filteredUpgrades.first?.value {
                return value[0]
            }
        }
        
        return nil
    }
    
    enum UpgradeCategories: String, CaseIterable {
        case astromechs
        case cannons
        case cargos
        case commands
        case configurations
        case crews
        case devices
        case forcepowers
        case gunners
        case hardpoints
        case illicits
        case missiles
        case modifications
        case sensors
        case tacticalrelays
        case talents
        case teams
        case techs
        case titles
        case torpedos
        case turrets
    }
}
