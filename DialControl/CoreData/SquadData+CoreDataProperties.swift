//
//  SquadData+CoreDataProperties.swift
//  DialControl
//
//  Created by Phil Kirby on 8/20/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
//

import Foundation
import CoreData


extension SquadData {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<SquadData> {
//        return NSFetchRequest<SquadData>(entityName: "SquadData")
//    }

    @NSManaged public var id: UUID?
    @NSManaged public var json: String?
    @NSManaged public var name: String?
    @NSManaged public var favorite: Bool
    @NSManaged public var engaged: Bool
    @NSManaged public var revealed: Bool
    @NSManaged public var firstPlayer: Bool
    
    /// way easier to use:
//    @NSManaged public var pilotState: Set<PilotState>
    
    /// than this:
    @NSManaged public var pilotState: NSSet?

}

// MARK: Generated accessors for pilotState
extension SquadData {

    @objc(addPilotStateObject:)
    @NSManaged public func addToPilotState(_ value: PilotState)

    @objc(removePilotStateObject:)
    @NSManaged public func removeFromPilotState(_ value: PilotState)

    @objc(addPilotState:)
    @NSManaged public func addToPilotState(_ values: NSSet)

    @objc(removePilotState:)
    @NSManaged public func removeFromPilotState(_ values: NSSet)

}

extension SquadData {
    func hasFaction(faction: Faction) -> Bool {
        let search = "\"faction\":\"\(faction.xwsID)\""
        
        guard let json = self.json else {
            return false
        }
        
        if json.contains(search) {
            return true
        }
        
        return false
    }
}

extension SquadData {
    func getShips() -> [ShipPilot] {
        let pilotStates = self
            .pilotStateArray
            .sorted(by: { $0.pilotIndex < $1.pilotIndex })
        
        pilotStates.forEach{ print("pilotStates[\($0.pilotIndex)] id:\(String(describing: $0.id))") }
        
        let zipped: Zip2Sequence<[SquadPilot], [PilotState]> = zip(squad.pilots, pilotStates)
        
        zipped.forEach{ print("\(String(describing: $0.0.name)): \($0.1)")}
        
        let ret = zipped.map{
            getShip(squad: squad, squadPilot: $0.0, pilotState: $0.1)
        }
        
        ret.printAll(tag: "PAK_DialStatus getShips()")
        
        return ret
    }
    
    private func getShip(squad: Squad, squadPilot: SquadPilot, pilotState: PilotState) -> ShipPilot {
        var shipJSON: String = ""
        
        print("shipName: \(squadPilot.ship)")
        print("pilotName: \(squadPilot.name)")
        print("faction: \(squad.faction)")
        print("pilotStateId: \(String(describing: pilotState.id))")
        
        return measure(name:"SquadData.getShip \(squadPilot.ship)") { () -> ShipPilot in
            shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
            
            var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]
            
            ship.pilots.removeAll()
            ship.pilots.append(foundPilots)
            
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            if let upgrades = squadPilot.upgrades {
                allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
            }
            
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points,
                             pilotState: pilotState)
        }
    }
}
