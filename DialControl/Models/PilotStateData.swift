//
//  PilotStateData.swift
//  DialControl
//
//  Created by Phil Kirby on 8/11/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation


struct UpgradeStateData : Codable, CustomStringConvertible {
    var force_active : Int?
    var force_inactive : Int?
    var charge_active : Int?
    var charge_inactive : Int?
    var selected_side : Int
    
    var description: String {
        var arr: [String] = []
    
        // -1 = not valid
        arr.append("force_active: \(force_active ?? -1)")
        arr.append("force_inactive: \(force_inactive ?? -1)")
        arr.append("charge_active: \(charge_active ?? -1)")
        arr.append("charge_inactive: \(charge_inactive ?? -1)")
        arr.append("selected_side: \(selected_side)")
        
        return arr.joined(separator: "\n")
    }
}

extension UpgradeStateData {
    mutating func updateForce(active: Int, inactive: Int) {
        force_active = active
        force_inactive = inactive
    }
    
    mutating func updateSelectedSide(side: Int) {
        selected_side = side
    }
    
    mutating func updateCharge(active: Int, inactive: Int) {
        charge_active = active
        charge_inactive = inactive
    }
}

struct PilotStateData : Codable, JSONSerialization, CustomStringConvertible {
    var pilot_index : Int
    var adjusted_attack : Int
    var adjusted_defense : Int
    var hull_active : Int
    var hull_inactive : Int
    var shield_active : Int
    var shield_inactive : Int
    var force_active : Int
    var force_inactive : Int
    var charge_active : Int
    var charge_inactive : Int
    var selected_maneuver: String
    var shipID: String
    var upgradeStates : [UpgradeStateData]?
    
    var description: String {
        var arr: [String] = []
    
        arr.append("pilot_index: \(pilot_index)")
        arr.append("adjusted_attack: \(adjusted_attack)")
        arr.append("adjusted_defense: \(adjusted_defense)")
        arr.append("hull_active: \(hull_active)")
        arr.append("hull_inactive: \(hull_inactive)")
        arr.append("shield_active: \(shield_active)")
        arr.append("shield_inactive: \(shield_inactive)")
        arr.append("force_active: \(force_active)")
        arr.append("force_inactive: \(force_inactive)")
        arr.append("charge_active: \(charge_active)")
        arr.append("charge_inactive: \(charge_inactive)")
        arr.append("selected_maneuver: \(selected_maneuver)")
        arr.append("shipdID: \(shipID)")
        
        if let upgradeStates = upgradeStates {
            arr.append("upgadeStates: \(upgradeStates.description)")
        }
        
        return arr.joined(separator: "\n")
    }
}

extension PilotStateData {
    func change(update: (inout PilotStateData) -> ()) {
        var newState = self
        update(&newState)
    }
    
    mutating func updateHull(active: Int, inactive: Int) {
        hull_active = active
        hull_inactive = inactive
    }
    
    mutating func updateForce(active: Int, inactive: Int) {
        force_active = active
        force_inactive = inactive
    }
    
    mutating func updateShield(active: Int, inactive: Int) {
        shield_active = active
        shield_inactive = inactive
    }
    
    mutating func updateCharge(active: Int, inactive: Int) {
        charge_active = active
        charge_inactive = inactive
    }
}
