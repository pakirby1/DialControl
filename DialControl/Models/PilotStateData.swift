//
//  PilotStateData.swift
//  DialControl
//
//  Created by Phil Kirby on 8/11/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

struct ChargeData<T> {
    let active: Int
    let inactive: Int
    let update: (_ active: Int, _ inactive: Int) -> T
    
    var min: Int {
        get { return 0 }
    }
    
    var max: Int {
        get { return active + inactive }
    }
    
    private func validate(value: Int) -> Int {
        if value >= max { return max }
        if value <= min { return min }
        
        return value
    }
    
    private func validate(newActive: Int, newInactive: Int) -> (Int, Int) {
        return (validate(value: newActive), validate(value: newInactive))
    }
    
    func decrement() -> T {
        let newActive = active - 1
        let newInactive = inactive + 1
        
        let x = validate(newActive: newActive, newInactive: newInactive)
        return update(x.0, x.1)
    }
    
    func increment() -> T {
        let newActive = active + 1
        let newInactive = inactive - 1
        
        let x = validate(newActive: newActive, newInactive: newInactive)
        return update(x.0, x.1)
    }
}


struct UpgradeStateData : Codable, CustomStringConvertible {
    var force_active : Int?
    var force_inactive : Int?
    var charge_active : Int?    // sides[].item[0].charges.value
    var charge_inactive : Int?
    var selected_side : Int
    var xws: String
    let id = UUID()
    
    var description: String {
        var arr: [String] = []
    
        // -1 = not valid
        arr.append("id: \(id)")
        arr.append("force_active: \(force_active ?? -1)")
        arr.append("force_inactive: \(force_inactive ?? -1)")
        arr.append("charge_active: \(charge_active ?? -1)")
        arr.append("charge_inactive: \(charge_inactive ?? -1)")
        arr.append("selected_side: \(selected_side)")
        
        return arr.joined(separator: "\n")
    }
}

extension UpgradeStateData {
    func change(update: (inout UpgradeStateData) -> ()) {
        var newState = self
        update(&newState)
    }
    
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
    
    mutating func reset() {
        if let active = charge_active, let inactive = charge_inactive {
            charge_active = active + inactive
            charge_inactive = 0
        }
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
    var upgradeStates : [UpgradeStateData]? // nil if no upgrades present
    var dial_status: DialStatus
    
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
        
        arr.append("dial_status: \(dial_status)")
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
        case dial_status
    }
    
}

extension PilotStateData {
    func getActive(type: StatButtonType) -> Int {
        switch(type) {
            case .hull:
                return hull.active
            case .force:
                return force.active
            case .charge:
                return charge.active
            case .shield:
                return shield.active
        }
    }
    
    func getInactive(type: StatButtonType) -> Int {
        switch(type) {
            case .hull:
                return hull.inactive
            case .force:
                return force.inactive
            case .charge:
                return charge.inactive
            case .shield:
                return shield.inactive
        }
    }
}


extension PilotStateData {
    typealias UpdateHandler = (inout PilotStateData) -> ()
    
    func update(type: PilotStatePropertyType_New) -> PilotStateData {
        switch(type) {
        case .hull(let active, let inactive):
            return change{ $0.updateHull(active: active, inactive: inactive) }
        case .shield(let active, let inactive):
            return change{ $0.updateShield(active: active, inactive: inactive) }
        case .force(let active, let inactive):
            return change{ $0.updateForce(active: active, inactive: inactive) }
        case .charge(let active, let inactive):
            return change{ $0.updateCharge(active: active, inactive: inactive) }
        case .shipIDMarker(let id):
            return change{ $0.updateShipID(shipID: id) }
        case .selectedManeuver(let maneuver):
            return change{ $0.updateManeuver(maneuver: maneuver) }
        case .revealAllDials(let revealed):
            return change{ $0.updateDialRevealed(revealed: revealed)}
        }
    }
    
    private func change(update: UpdateHandler) -> PilotStateData {
        var newState = self
        update(&newState)
        return newState
    }
    
    func change(update: (inout PilotStateData) -> ()) {
        var newState = self
        update(&newState)
    }
    
    private mutating func reset(activeKeyPath: WritableKeyPath<PilotStateData, Int>,
                     inactiveKeyPath: WritableKeyPath<PilotStateData, Int>)
    {
        let currentActive = self[keyPath: activeKeyPath]
        let currentInactive = self[keyPath: inactiveKeyPath]
        
        self[keyPath: activeKeyPath] = currentActive + currentInactive
        self[keyPath: inactiveKeyPath] = 0
    }
    
    mutating func reset() {
        reset(activeKeyPath: \.hull_active, inactiveKeyPath: \.hull_inactive)
        reset(activeKeyPath: \.shield_active, inactiveKeyPath: \.shield_inactive)
        reset(activeKeyPath: \.force_active, inactiveKeyPath: \.force_inactive)
        reset(activeKeyPath: \.charge_active, inactiveKeyPath: \.charge_inactive)
        
        var updatedUpgradeStates: [UpgradeStateData] = []
        
        if let _ = self.upgradeStates {
            upgradeStates?.forEach { upgrade in
                upgrade.change { upgrade in
                    upgrade.reset()
                    updatedUpgradeStates.append(upgrade)
                }
            }
            
            self.upgradeStates = updatedUpgradeStates
            self.updateDialStatus(status: .hidden)
        }
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
    
    mutating func updateDialStatus(status: DialStatus) {
        dial_status = status
    }
    
    mutating func updateShipID(shipID: String) {
        self.shipID = shipID
    }
    
    mutating func updateDialRevealed(revealed: Bool) {
        self.dial_status = (revealed ? .revealed : .hidden)
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

extension PilotStateData {
    /// Use key paths to return a closure that updates the properties on self.
    // let update = buildUpdate(activeKeyPath: \.shield_active,
    //    inactiveKeyPath: \.shield_inactive)
    func buildUpdate(activeKeyPath: WritableKeyPath<PilotStateData, Int>,
                     inactiveKeyPath: WritableKeyPath<PilotStateData, Int>) -> (Int, Int) -> Self
    {
        let ret: (Int, Int) -> Self = { (active: Int, inactive: Int) -> Self in
            return self.change() { psd in
                psd[keyPath: activeKeyPath] = active
                psd[keyPath: inactiveKeyPath] = inactive
            }
        }
        
        return ret
    }
    
    typealias PilotStateDataCharge = ChargeData<PilotStateData>
    
    var hull: PilotStateDataCharge {
        get {
            let update = buildUpdate(activeKeyPath: \.hull_active,
                                     inactiveKeyPath: \.hull_inactive)
            
            return PilotStateDataCharge(active: self.hull_active,
                                               inactive: self.hull_inactive,
                                               update: update)
        }
    }
    
    var shield: PilotStateDataCharge {
        get {
            let update = buildUpdate(activeKeyPath: \.shield_active,
                                     inactiveKeyPath: \.shield_inactive)
            
            return PilotStateDataCharge(active: self.shield_active,
                                               inactive: self.shield_inactive,
                                               update: update)
        }
    }
    
    var force: PilotStateDataCharge {
        get {
            let update = buildUpdate(activeKeyPath: \.force_active,
                                     inactiveKeyPath: \.force_inactive)
            
            return PilotStateDataCharge(active: self.force_active,
                                               inactive: self.force_inactive,
                                               update: update)
        }
    }
    
    var charge: PilotStateDataCharge {
        get {
            let update = buildUpdate(activeKeyPath: \.charge_active,
                                     inactiveKeyPath: \.charge_inactive)
            
            return PilotStateDataCharge(active: self.charge_active,
                                               inactive: self.charge_inactive,
                                               update: update)
        }
    }
    
}

protocol PilotStateDataProtocol {
    
}

enum DialStatus: Codable {
    case hidden
    case revealed
    case set
    case destroyed   // Ship Destroyed
    case ionized
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        switch try container.decode(String.self) {
            case "hidden": self = .hidden
            case "revealed": self = .revealed
            case "set": self = .set
            case "destroyed": self = .destroyed
            case "ionized": self = .ionized
            default: fatalError()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .hidden: try container.encode("hidden")
            case .revealed: try container.encode("revealed")
            case .set: try container.encode("set")
            case .destroyed: try container.encode("destroyed")
            case .ionized: try container.encode("ionized")
        }
    }
}

extension DialStatus {
    mutating func handleEvent(event: DialStatusEvent) {
        switch(self, event) {
            // Ship View
            case (.hidden, .setDial) : self = .set
            case (.revealed, .setDial) : self = .set
            case (.set, .unsetDial) : self = .hidden
    
            // Squad View
            case (.set, .dialTapped) : self = .revealed
            case (.set, .revealAll) : self = .revealed
            case (.set, .hideAll) : self = .hidden
            case (.revealed, .dialTapped) : self = .hidden
            case (.revealed, .hideAll) : self = .hidden
            case (.hidden, .dialTapped) : self = .revealed
            case (.hidden, .revealAll) : self = .revealed
            case (.ionized, .dialTapped) : self = .revealed
            case (.ionized, .revealAll) : self = .revealed
            case (.ionized, .hideAll) : self = .hidden
            default: self = .hidden
        }
    }
    
    var isFlipped: Bool {
        switch(self) {
            case .hidden: return false
            case .revealed: return true
            case .set: return true
            case .destroyed: return false
            case .ionized: return true
        }
    }
}

extension DialStatus : CustomStringConvertible {
    var description: String {
        switch(self) {
            case .hidden: return "Hidden"
            case .revealed: return "Revealed"
            case .set: return "Set"
            case .destroyed: return "Destroyed"
            case .ionized: return "Ionized"
        }
    }
}

enum DialStatusEvent {
    // Ship View
    case setDial
    case unsetDial
    
    // Squad View
    case dialTapped
    case revealAll
    case hideAll
}

struct Transition {
    let currentState: DialStatus
    let event: DialStatusEvent
    let nextState: DialStatus
}
