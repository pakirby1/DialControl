//
//  UpgradeUtility.swift
//  DialControl
//
//  Created by Phil Kirby on 9/17/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

struct UpgradeUtility {
    static func buildAllUpgrades(_ upgrades: SquadPilotUpgrade) -> [Upgrade] {
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
        
        func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
            let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
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
