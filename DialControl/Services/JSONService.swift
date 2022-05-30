//
//  JSONService.swift
//  DialControl
//
//  Created by Phil Kirby on 4/7/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation

protocol JSONServiceProtocol {
    func loadShipFromJSON(shipName: String,
                          pilotName: String,
                          faction: String) -> (Ship, Pilot)
}

struct ShipCacheKey {
    let shipName: String
}

class JSONService : JSONServiceProtocol {
    let cacheService: CacheServiceProtocol
    
    init(cacheService: CacheServiceProtocol) {
        self.cacheService = cacheService
    }
    
    /// What do we return if we encounter an error (empty file)?
    func loadShipFromJSON(shipName: String,
                          pilotName: String,
                          faction: String) -> (Ship, Pilot)
    {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        global_os_log("loadShipFromJSON_New", [shipName, pilotName, faction].joined(separator: ", "))
        
        let key = ShipFactionCacheKey(shipName: shipName, faction: faction)
        
        guard let ship = cacheService.getShip(key: key) else {
            global_os_log("loadShipFromJSON_New cache miss", key.description)
            shipJSON = getJSONFor(ship: shipName, faction: faction)
            
            /// Cache the Ship by shipName xws -> Ship
            let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            let pilot = ship.getPilot(pilotName: pilotName)
            cacheService.setShip(key: key, value: ship)
            return (ship, pilot)
        }
        
        global_os_log("loadShipFromJSON_New cache hit", key.description)
        let pilot = ship.getPilot(pilotName: pilotName)
        return (ship, pilot)
    }
    
    /// The default path for pilots
    static var pilotsPrefix: String { "https://pakirby1.github.io/Images/XWing/Pilots/" }
    
    /// The default path for upgrades
    static var upgradesPrefix: String { "https://pakirby1.github.io/Images/XWing/Upgrades/" }
    
    /// Build a list of URLs for all Images
    ///     pilots[]/{xws}.png
    ///     upgrades[]/{xws}.png
    ///     upgrades[]/{xws}-sideb.png
    /// - Parameter path: The absolute path of the page.
    /// - Parameter content: The page's content.
    func getAllImageURLs() {
        // Get all pilots
        let pilots = readRecursive(directory: "Data\\Pilots")
    }
    
    /// Builds a list of URLS that exist within the `directory` sub directory of the main bundle
    /// - Parameter directory: Sub directory of the main bundle ("Data\\Pilots").
    func readRecursive(directory: String) -> [URL] {
        guard let directoryURL = URL(string: directory, relativeTo: Bundle.main.bundleURL) else {
            return []
        }
        
        let localFileManager = FileManager()
         
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
        let directoryEnumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
         
        var fileURLs: [URL] = []
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let isDirectory = resourceValues.isDirectory,
                let name = resourceValues.name
                else {
                    continue
            }
            
            if isDirectory {
                if name == "_extras" {
                    directoryEnumerator.skipDescendants()
                }
            } else {
                fileURLs.append(fileURL)
            }
        }
         
        logMessage("file URLs: \(fileURLs.count)")
        return fileURLs
    }
}
