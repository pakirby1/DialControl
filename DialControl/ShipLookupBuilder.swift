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
    static func buildShipLookupTable() -> [String:Array<PilotFileUrl>] {
        var ret : [String:Array<PilotFileUrl>] = [:]
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/pilots"
        var fileCount: Int = 0
        
        // Because sloppy filename convention that doesn't match xws in json
        let exceptions:[(String, String)] = [
            ("upsilon-class-command-shuttle", "upsilonclassshuttle"),
            ("mg-100-starfortress-sf-17", "mg100starfortress")
        ]
        
        func processDirectory(dir: String) {
            func buildKey(filename: String) -> String {
                print("\(#function) \(filename)")
                
                for exception in exceptions {
                    if filename == exception.0 {
                        return exception.1
                    }
                }
                
                return filename.removeAll(character: "-")
            }
            
            func processFile(file: String, dir: String) {
                print("\t\(file)")
                let filename = file.fileName()  // tie-ln-fighter.json
                let key = buildKey(filename: filename)    // tielnfighter
                let directoryPath = "pilots/" + dir // pilots/rebel-alliance
                let faction = dir.removeAll(character: "-")
                let pfu = PilotFileUrl(fileName: file,
                                       directoryPath: directoryPath,
                                       faction: faction)
                
                if let array = ret[key] {
                    var newArray = array
                    newArray.append(pfu)
                    ret[key] = newArray
                    print("\(#function) \(pfu.faction) \(pfu.fileName)")
                } else {
                    print("\(#function) adding \(key)")
                    print("\(#function) \(pfu.faction) \(pfu.fileName)")
                    ret[key] = [pfu]
                }
            }
            
            print("\(#function) \(dir)")
            
            do {
                let subDir = path + "/" + dir
                let files = try fm.contentsOfDirectory(atPath: subDir)
                
                for file in files {
                    fileCount += 1
                    processFile(file: file, dir: dir)
                }
            }
            catch {
                print(error)
            }
        }

        print("\(#function) \(path)")
        
        do {
            let dirs = try fm.contentsOfDirectory(atPath: path)

            for dir in dirs {
                processDirectory(dir: dir)
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error)
        }
        
        print("\(#function) file count \(fileCount)")
        print("\(#function) processed \(ret.count) files")
        
        for i in ret.enumerated() {
            print("\(#function) \(i.element.key)\t\(i.element.value)\n")
        }
        
        return ret
    }
}
