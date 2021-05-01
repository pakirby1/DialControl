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
                          squad: Squad) -> (Ship, Pilot)
}

class JSONService : JSONServiceProtocol {
    /// What do we return if we encounter an error (empty file)?
    func loadShipFromJSON(shipName: String,
                          pilotName: String,
                          squad: Squad) -> (Ship, Pilot)
    {
        func loadShipFromJSON_Old(shipName: String, pilotName: String, squad: Squad) -> (Ship, Pilot) {
            var shipJSON: String = ""
            
            print("shipName: \(shipName)")
            print("pilotName: \(pilotName)")
            
            shipJSON = getJSONFor(ship: shipName, faction: squad.faction)
            
            let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            let foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0].asPilot()
            
            return (ship, foundPilots)
        }
        
        func loadShipFromJSON_New(shipName: String, pilotName: String, squad: Squad) -> (Ship, Pilot)
        {
            var shipJSON: String = ""
            
            print("shipName: \(shipName)")
            print("pilotName: \(pilotName)")
            
            shipJSON = getJSONFor(ship: shipName, faction: squad.faction)
            
            let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            var foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0].asPilot()
            
            /// Update image to point to "https://pakirby1.github.io/Images/XWing/Pilots/{pilotName}.png
            foundPilots.image = ImageUrlTemplates.buildPilotUrl(xws: pilotName)
            
            return (ship, foundPilots)
        }
        
        if FeaturesManager.shared.isFeatureEnabled(.UpdateImageUrls) {
            return loadShipFromJSON_New(shipName: shipName, pilotName: pilotName, squad: squad)
        } else {
            return loadShipFromJSON_Old(shipName: shipName, pilotName: pilotName, squad: squad)
        }
    }
    
}
