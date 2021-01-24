//
//  PilotStateService.swift
//  DialControl
//
//  Created by Phil Kirby on 8/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import CoreData

protocol PilotStateServiceProtocol : class {
    var moc: NSManagedObjectContext { get }
    func savePilotState(squadData: SquadData, state: String, pilotIndex: Int)
    func updatePilotState(pilotState: PilotState, state: String, pilotIndex: Int)
    func createPilotState(squad: Squad, squadData: SquadData)
    func updateState(newData: PilotStateData, state: PilotState)
}

class PilotStateService: PilotStateServiceProtocol, ObservableObject {
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func updateState(newData: PilotStateData, state: PilotState) {
        print("\(Date()) PAK_updateState: \(newData.description)")
        
        let json = PilotStateData.serialize(type: newData)
        
        self.updatePilotState(pilotState: state,
                              state: json,
                              pilotIndex: newData.pilot_index)
    }
    
    func createPilotState(squad: Squad, squadData: SquadData) {
        func calculate_force_active(ship: Ship,
                                    squadPilot: SquadPilot,
                                    allUpgrades: [Upgrade]) -> Int
        {

//            allUpgrades.reduce(0, { $0.})
            let forceUpgrades = allUpgrades.filter{ upgrade in
                if let _ = upgrade.sides[0].force {
                    return true
                }
                
                return false
            }
            
            let forceValues = forceUpgrades.reduce(0, {
                return $0 + (($1.sides[0].force?.value) ?? 0)
            })
            
            return ship.pilotForce(pilotId: squadPilot.id) + forceValues
        }
        
        //
        func calculateActiveHull(ship: Ship,
                                 squadPilot: SquadPilot,
                                 allUpgrades: [Upgrade]) -> Int
        {
            var adj = 0
            
            let hullUpgrade = allUpgrades.filter{ upgrade in
                upgrade.xws == "hullupgrade"
            }
            
            if hullUpgrade.count == 1 {
                adj += 1
            }
            
            let soullessoneUpgrade = allUpgrades.filter{ upgrade in
                upgrade.xws == "soullessone"
            }
            
            if soullessoneUpgrade.count == 1 {
                adj += 2
            }
            
            return ship.hullStats + adj
        }
        
        func calculateActiveShields(ship: Ship,
                                 squadPilot: SquadPilot,
                                 allUpgrades: [Upgrade]) -> Int
        {
            var adj = 0
            
            let shieldUpgrade = allUpgrades.filter{ upgrade in
                upgrade.xws == "shieldupgrade"
            }
            
            if shieldUpgrade.count == 1 {
                adj += 1
            }
            
            let viragoUpgrade = allUpgrades.filter{ upgrade in
                upgrade.xws == "virago"
            }
            
            if viragoUpgrade.count == 1 {
                adj += 1
            }
            
            return ship.shieldStats + adj
        }
        
        func buildUpgradeStates(allUpgrades : [Upgrade]) -> [UpgradeStateData] {
            var ret:[UpgradeStateData] = []
            
            // for every upgrade with sides[].item[0].charges.value > 1
            allUpgrades.forEach{ upgrade in
                if let charge = upgrade.sides[0].charges?.value {
                    // create an UpgradeStateData
                    ret.append(UpgradeStateData(force_active: nil,
                                                force_inactive: nil,
                                                charge_active: charge,
                                                charge_inactive: 0,
                                                selected_side: 0,
                                                xws: upgrade.xws))
                }
            }
                
            return ret
        }
        
        func buildPilotStateData(squad: Squad,
                                 squadPilot: SquadPilot,
                                 pilotIndex: Int) -> String
        {
            var shipJSON: String = ""
            shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
            
            let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            
            // Calculate new adjusted values based on upgrades (Hull Upgrade, Delta-7B, etc.)
            
            let arc = ship.arcStats
            let agility = ship.agilityStats
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
            if let upgrades = squadPilot.upgrades {
                allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
            }
            
            let pilotStateData = PilotStateData(
                pilot_index: pilotIndex,
                adjusted_attack: arc,
                adjusted_defense: agility,
                hull_active: calculateActiveHull(ship: ship, squadPilot: squadPilot, allUpgrades: allUpgrades),
                hull_inactive: 0,
                shield_active: calculateActiveShields(ship: ship, squadPilot: squadPilot, allUpgrades: allUpgrades),
                shield_inactive: 0,
                force_active: calculate_force_active(ship: ship, squadPilot: squadPilot, allUpgrades: allUpgrades),
                force_inactive: 0,
                charge_active: ship.pilotCharge(pilotId: squadPilot.id),
                charge_inactive: 0,
                selected_maneuver: "",
                shipID: "",
                upgradeStates: buildUpgradeStates(allUpgrades: allUpgrades),
                dial_status: DialStatus.hidden
            )
            
            let json = PilotStateData.serialize(type: pilotStateData)
            return json
        }
        
        var pilotIndex: Int = 0
        
        // for each pilot in squad.pilots
        for pilot in squad.pilots {
            // get the ship
            let json = buildPilotStateData(squad: squad,
                                               squadPilot: pilot,
                                               pilotIndex: pilotIndex)
            
            savePilotState(squadData: squadData,
                           state: json,
                           pilotIndex: pilotIndex)
            
            pilotIndex += 1
        }
    }
    
    func savePilotState(squadData: SquadData,
                        state: String,
                        pilotIndex: Int)
    {
        let pilotState = PilotState(context: self.moc)
        pilotState.id = UUID()
        pilotState.squadData = squadData
        pilotState.json = state
        pilotState.pilotIndex = Int32(pilotIndex)
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
    }
    
    func updatePilotState(pilotState: PilotState,
                        state: String,
                        pilotIndex: Int)
    {
        pilotState.json = state
        pilotState.pilotIndex = Int32(pilotIndex)
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
    }
}
