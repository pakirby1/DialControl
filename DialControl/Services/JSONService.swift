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

class JSONService : JSONServiceProtocol {
    /// What do we return if we encounter an error (empty file)?
    func loadShipFromJSON(shipName: String,
                          pilotName: String,
                          faction: String) -> (Ship, Pilot)
    {
        if FeaturesManager.shared.isFeatureEnabled(.loadloadShipFromJSON)
        {
            return loadShipFromJSON_New(shipName: shipName, pilotName: pilotName, faction: faction)
        }
        else {
            return loadShipFromJSON_Old(shipName: shipName, pilotName: pilotName, faction: faction)
        }
    }
    
    func loadShipFromJSON_New(shipName: String,
                          pilotName: String,
                          faction: String) -> (Ship, Pilot)
    {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        global_os_log("loadShipFromJSON_New", [shipName, pilotName, faction].joined(separator: ", "))
        
        /*
         do we have a (Ship, Pilot) already in the cache for this shipName & pilotName, faction combination?
         
            delta7aethersprite, obiwankenobi, galacticrepublic
         
            the cache key could be a String :
         
            delta7aethersprite, obiwankenobi, galacticrepublic
         
            let key = [shipName, pilotName, faction].joined(".")
         
            "delta7aethersprite.obiwankenobi.galacticrepublic"
         
         
            guard let cachedShip = cache(key) else {
                global_os_log("loadShipFromJSON_New cache miss", [shipName, pilotName, faction].joined(separator: ", "))
         
                let ship: (Ship, Pilot) = loadShipFromJSON_Old(shipName, pilotName, faction)
                cache.store(key, ship)
                return ship
            }
         
            global_os_log("loadShipFromJSON_New cache hit", [shipName, pilotName, faction].joined(separator: ", "))
         
            return cachcedShip
         */
        // check the `cache` for this ship, pilot combination
        /// Cache the ship JSON so that we don't have to read from the file system each time
        shipJSON = getJSONFor(ship: shipName, faction: faction)
        
        /// Cache the Ship by xws xws -> Ship
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        var foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0].asPilot()
        
        /// Update image to point to "https://pakirby1.github.io/Images/XWing/Pilots/{pilotName}.png
        foundPilots.image = ImageUrlTemplates.buildPilotUrl(xws: pilotName)
        
        return (ship, foundPilots)
    }
    
    func loadShipFromJSON_Old(shipName: String,
                          pilotName: String,
                          faction: String) -> (Ship, Pilot)
    {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        global_os_log("loadShipFromJSON_Old", [shipName, pilotName, faction].joined(separator: ", "))
        
        // check the `cache` for this ship, pilot combination
        shipJSON = getJSONFor(ship: shipName, faction: faction)
        
        /// Cache the Ship by xws
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        var foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0].asPilot()
        
        /// Update image to point to "https://pakirby1.github.io/Images/XWing/Pilots/{pilotName}.png
        foundPilots.image = ImageUrlTemplates.buildPilotUrl(xws: pilotName)
        
        return (ship, foundPilots)
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
