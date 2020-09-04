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
    var dial_revealed: Bool
    
    var id = UUID()
    
    var description: String {
        var arr: [String] = []
        
        arr.append("id: \(id)")
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
        arr.append("shipID: \(shipID)")
        
        if let upgradeStates = upgradeStates {
            arr.append("upgadeStates: \(upgradeStates.description)")
        }
        
        arr.append("dial_revealed: \(dial_revealed)")
        return arr.joined(separator: "\n")
    }
    
    var hullMax: Int { return self.hull_active + self.hull_inactive }
    var shieldsMax: Int { return self.shield_active + self.shield_inactive }
    var forceMax: Int { return self.force_active + self.force_inactive }
    var chargeMax: Int { return self.charge_active + self.charge_inactive }
    
    enum CodingKeys: String, CodingKey {
        case pilot_index
        case adjusted_attack
        case adjusted_defense
        case hull_active
        case hull_inactive
        case shield_active
        case shield_inactive
        case force_active
        case force_inactive
        case charge_active
        case charge_inactive
        case selected_maneuver
        case shipID
        case upgradeStates
        case dial_revealed
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
    
    mutating func updateManeuver(maneuver: String) {
        selected_maneuver = maneuver
    }
    
    mutating func updateShipID(shipID: String) {
        self.shipID = shipID
    }
    
    mutating func updateDialRevealed(revealed: Bool) {
        self.dial_revealed = revealed
    }
    
    var health: Int {
        hull_active + hull_inactive + shield_active + shield_inactive
    }
    
    var halfHealth: Int {
        let ret: Int
        
        if health.isMultiple(of: 2) {
            ret = (health / 2)
        } else {
            ret = (health + 1) / 2
        }
        
        return ret
    }
    
    var isHalved: Bool {
        let currentDamage = hull_inactive + shield_inactive
        
        if currentDamage >= halfHealth {
            return true
        }
        
        return false
    }
    
    var isDestroyed: Bool {
        let noHull = (hull_active == 0)
        let noShields = (shield_active == 0)
        
        if noHull && noShields {
            return true
        }
        
        return false
    }
}
