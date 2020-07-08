//
//  ShipLookupBuilder.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

struct PilotFileUrl: CustomStringConvertible {
    let fileName: String
    let directoryPath: String
    
    var description: String {
        return "fileName: '\(fileName)' directoryPath: '\(directoryPath)'"
    }
}

// MARK:- Code generation helper for upgrades
struct ShipLookupBuilder {
    static func buildUpgradeVariable(upgrade: String) {
        let plural = "\(upgrade)s"
        
        let template = """
            let \(plural) : [Upgrade] = upgrades
                .\(plural)
                .map{ getUpgrade(upgradeCategory: "\(upgrade)", upgradeName: $0) }
        
        """
        
        print(template)
    }

    static func buildPublicVar(upgrade: String) -> String {
        let publicVar = "var \(upgrade)s: [String] { return _\(upgrade) ?? [] }"
        return publicVar
    }
    
    static func buildPrivateVar(upgrade: String) -> String {
        let privateVar = "private var _\(upgrade): [String]?"
        return privateVar
    }
    
    static func buildCodingKey(upgrade: String) -> String {
        let codingKey = "case _\(upgrade) = \"\(upgrade)\""
        return(codingKey)
    }
    
    static func buildAllUpgradesText() {
        
        var allUpgrades: [String] = []
        var publicVars: [String] = []
        var privateVars: [String] = []
        var codingKeys: [String] = []
        
        
        
        for upgrade in UpgradeCardEnum.allCases {
            let formatted = "\(upgrade)".removeAll(character: "(\"\")")
           
            allUpgrades.append("allUpgrades.append(" + formatted + "s)")
           buildUpgradeVariable(upgrade: formatted)
           publicVars.append(buildPublicVar(upgrade: formatted))
           privateVars.append(buildPrivateVar(upgrade: formatted))
           codingKeys.append(buildCodingKey(upgrade: formatted))
        }
        
//        let allUpgrades = "allUpgrades " + UpgradeCardEnum.allCases.joined(separator: " + ")
//        allUpgrades = allUpgrades.removeAll(character: "(\"\")")
        
        print("\nSquadCardView.getShips()\n")
        allUpgrades.forEach{ print($0) }
        
        /// public vars
        print("\nSquadPilotUpgrade public vars\n")
        publicVars.forEach{ print($0) }
        
        print("\nSquadPilotUpgrade private vars\n")
        privateVars.forEach{ print($0) }
        
        print("\nSquadPilotUpgrade coding keys\n")
        codingKeys.forEach{ print($0) }
    }
}

extension ShipLookupBuilder {
    static func buildLookup() -> [String:PilotFileUrl] {
        var ret : [String:PilotFileUrl] = [:]
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/pilots"
        
        print(path)
        
        do {
            let dirs = try fm.contentsOfDirectory(atPath: path)

            for dir in dirs {
                print("\(dir)")
                let subDir = path + "/" + dir
                let files = try fm.contentsOfDirectory(atPath: subDir)
                
                for file in files {
                    print("\t\(file)")
                    let filename = file.fileName()  // tie-ln-fighter.json
                    var key = filename.removeAll(character: "-")    // tielnfighter
                    let directoryPath = "pilots/" + dir // rebel-alliance
                    
                    if dir == "rebel-alliance" {
                        key = "rebel" + key // rebeltielnfighter
                    }
                    
                    let pfu = PilotFileUrl(fileName: file,
                                           directoryPath: directoryPath)
                    ret[key] = pfu
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error)
        }
        
        return ret
    }
}
