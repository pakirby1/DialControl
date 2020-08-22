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
}

class PilotStateService: PilotStateServiceProtocol {
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func createPilotState(squad: Squad, squadData: SquadData) {
        var pilotIndex: Int = 0
        
        // for each pilot in squad.pilots
        for pilot in squad.pilots {
            // get the ship
            let shipPilot: ShipPilot = getShip(squad: squad, squadPilot: pilot)
            
            // Calculate new adjusted values based on upgrades (Hull Upgrade, Delta-7B, etc.)
            
            let arc = shipPilot.arcStats
            let agility = shipPilot.agilityStats
            
            let pilotStateData = PilotStateData(
                pilot_index: pilotIndex,
                adjusted_attack: arc,
                adjusted_defense: agility,
                hull_active: shipPilot.hullStats,
                hull_inactive: 0,
                shield_active: shipPilot.shieldStats,
                shield_inactive: 0,
                force_active: shipPilot.forceStats,
                force_inactive: 0,
                charge_active: shipPilot.chargeStats,
                charge_inactive: 0,
                selected_maneuver: "",
                shipID: "",
                upgradeStates: []
            )
            
            let json = PilotStateData.serialize(type: pilotStateData)
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
