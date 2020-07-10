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
    let faction: String
    
    var description: String {
        return "fileName: '\(fileName)' directoryPath: '\(directoryPath)' faction: '\(faction)'"
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
    
    /// Due to naming collisions on the dictionary key
    ///    Current
    //    arc170starfighter -> PFU(arc-170-starfighter.json, pilots/rebel-alliance)
    //    arc170starfighter -> PFU(arc-170-starfighter.json, pilots/galactic-republic)
    //    tielnfighter -> PFU(tie-ln-fighter.json. pilots/rebel-alliance)
    //    tielnfighter -> PFU(tie-ln-fighter.json. pilots/galactic-empire)
    //
    //
    
    static func buildLookup_Old() -> [String:PilotFileUrl] {
        var ret : [String:PilotFileUrl] = [:]
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/pilots"
        
        func processDirectory(dir: String) {
            func processFile(file: String, dir: String) {
                print("\t\(file)")
                let filename = file.fileName()  // tie-ln-fighter.json
                let key = filename.removeAll(character: "-")    // tielnfighter
                let directoryPath = "pilots/" + dir // rebel-alliance
                let faction = dir.removeAll(character: "-")
                let pfu = PilotFileUrl(fileName: file,
                                       directoryPath: directoryPath,
                                       faction: faction)
                ret[key] = pfu
            }
            
            print("\(dir)")
                
            do {
                let subDir = path + "/" + dir
                let files = try fm.contentsOfDirectory(atPath: subDir)
                
                for file in files {
                    processFile(file: file, dir: dir)
                }
            }
            catch {
                print(error)
            }
        }

        print(path)
        
        do {
            let dirs = try fm.contentsOfDirectory(atPath: path)

            for dir in dirs {
                processDirectory(dir: dir)
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error)
        }
        
        return ret
    }
    
    ///    Proposed
    //    arc170starfighter -> [ PFU(arc-170-starfighter.json, pilots/rebel-alliance),
    //                           PFU(arc-170-starfighter.json, pilots/galactic-republic) }
    //
    //    tielnfighter -> [ PFU(tie-ln-fighter.json. pilots/rebel-alliance),
    //                      PFU(tie-ln-fighter.json. pilots/galactic-empire) ]
    //
    //    rz1awing -> [ PFU(rz-1-a-wing.json, pilots/rebel-alliance) ]
    // "arc170starfighter": [fileName: 'arc-170-starfighter.json' directoryPath: 'pilots/galactic-republic', fileName: 'arc-170-starfighter.json' directoryPath: 'pilots/rebel-alliance']
    // "tielnfighter": [fileName: 'tie-ln-fighter.json' directoryPath: 'pilots/galactic-empire', fileName: 'tie-ln-fighter.json' directoryPath: 'pilots/rebel-alliance']
    static func buildLookup_New() -> [String:Array<PilotFileUrl>] {
        var ret : [String:Array<PilotFileUrl>] = [:]
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/pilots"
        
        func processDirectory(dir: String) {
            func processFile(file: String, dir: String) {
                print("\t\(file)")
                let filename = file.fileName()  // tie-ln-fighter.json
                let key = filename.removeAll(character: "-")    // tielnfighter
                let directoryPath = "pilots/" + dir // rebel-alliance
                let faction = dir.removeAll(character: "-")
                let pfu = PilotFileUrl(fileName: file,
                                       directoryPath: directoryPath,
                                       faction: faction)
                 
                if let array = ret[key] {
                    var newArray = array
                    newArray.append(pfu)
                    ret[key] = newArray
                } else {
                    ret[key] = [pfu]
                }
            }
            
            print("\(dir)")
                
            do {
                let subDir = path + "/" + dir
                let files = try fm.contentsOfDirectory(atPath: subDir)
                
                for file in files {
                    processFile(file: file, dir: dir)
                }
            }
            catch {
                print(error)
            }
        }

        print(path)
        
        do {
            let dirs = try fm.contentsOfDirectory(atPath: path)

            for dir in dirs {
                processDirectory(dir: dir)
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error)
        }
        
        return ret
    }
}
