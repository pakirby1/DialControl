//
//  Ship.swift
//  DialControl
//
//  Created by Phil Kirby on 3/14/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

protocol ShipProtocol {
    var dial: [String] { get }
}

struct Stat: Codable {
    var arc: String { return _arc ?? "" }
    let type: String
    let value: Int
    private var _arc: String?

    enum CodingKeys: String, CodingKey {
        case _arc = "arc"
        case type
        case value
    }
}

struct Action: Codable {
    let difficulty: String
    let type: String
}

struct ShipAbility: Codable {
    let name: String
    let text: String
}

enum Slot: String, Codable {
    case Modification
    case Talent
    case Sensor
    case Missile
    case Force = "Force Power"
    case Illicit
    case Astromech
    case Device
    case Gunner
    case Crew
    case Cannon
    case Cargo
    case Command
    case Configuration
    case Hardpoint
    case Relay = "Tactical Relay"
    case Team
    case Tech
    case Title
    case Torpedo
    case Turret
}

struct Force: Codable {
    let value: Int
    let recovers: Int
}

struct Charges: Codable {
    let value: Int
    let recovers: Int
}

struct PilotDTO: Codable {
    let name: String
    let initiative: Int
    let limited: Int
    let cost: Int
    let xws: String
    var text: String { return _text ?? "" }
    var shipAbility: ShipAbility? { return _shipAbility ?? nil }
    var slots: [Slot]? { return _slots ?? [] }
    var artwork: String { return _artwork ?? "" }
    var force: Force? { return _force ?? nil }
    var charges: Charges? { return _charges ?? nil }
    var standardLoadout : [String]? { return _standardLoadout ?? nil }
    var shipStats: [Stat]? { return _shipStats ?? [] }
    
    private var _text: String?
    private var _force: Force?
    private var _charges: Charges?
    private var _shipAbility: ShipAbility?
    private var _slots: [Slot]?
    private var _artwork: String?
    private var _standardLoadout : [String]?
    private var _shipStats: [Stat]?
    
    enum CodingKeys: String, CodingKey {
        case _text = "text"
        case name
        case initiative
        case limited
        case cost
        case xws
        case _shipAbility = "shipAbility"
        case _slots = "slots"
        case _artwork = "artwork"
        case _force = "force"
        case _charges = "charges"
        case _standardLoadout = "standardLoadout"
        case _shipStats = "shipStats"
    }
}

extension PilotDTO {
    func asPilot() -> Pilot {
        return Pilot(
            name: self.name,
            initiative: self.initiative,
            limited: self.limited,
            cost: self.cost,
            xws: self.xws,
            text: self.text,
            image: "",
            shipAbility: self.shipAbility,
            slots: self.slots,
            artwork: self.artwork,
            force: self.force,
            charges: self.charges
        )
    }
}

struct Pilot {
    let name: String
    let initiative: Int
    let limited: Int
    let cost: Int
    let xws: String
    var text: String
    var image: String
    var shipAbility: ShipAbility?
    var slots: [Slot]?
    let artwork: String
    var force: Force?
    var charges: Charges?
}

struct Ship: Codable, JSONSerialization {
    let name: String
    var xws: String { return _xws ?? "" }
    var size: String { return _size ?? "" }
    var dial: [String] { return _dial ?? [] }
    var dialCodes: [String] { return _dialCodes ?? [] }
    let faction: String
    let stats: [Stat]
    let actions: [Action]
    let icon: String
    var pilots: [PilotDTO]
    
    private var _xws: String?
    private var _size: String?
    private var _dial: [String]?
    private var _dialCodes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case _xws = "xws"
        case _size = "size"
        case _dial = "dial"
        case _dialCodes = "dialCodes"
        case faction = "faction"
        case stats = "stats"
        case actions = "actions"
        case icon = "icon"
        case pilots = "pilots"
    }
    
    static func serializeJSON(jsonString: String) -> Ship {
        return deserialize(jsonString: jsonString)
    }
    
    static func deserializeJSON(jsonString: String) throws -> Ship {
        return try deserialize_throws(jsonString: jsonString)
    }
}

extension Ship {
    var agilityStats: Int {
        let stats: [Stat] = self.stats.filter{ $0.type == "agility"}
            
            if (stats.count > 0) {
                return stats[0].value
            } else {
                return 0
            }
    }
    


    struct FiringArc {
        let type: FiringArcType
        let value: Int
        
        init(type: String, value: Int) {
            self.type = FiringArcType(type)
            self.value = value
        }
        
        var healthStat: HealthStat {
            return HealthStat(type: .attack(type), value: self.value)
        }
    }
    
    enum FiringArcType: String {
        case frontArc = "Front Arc"
        case singleTurretArc = "Single Turret Arc"
        case bullseyeArc = "Bullseye Arc"
        case fullFrontArc = "Full Front Arc"
        case doubleTurretArc = "Double Turret Arc"
        case rearArc = "Rear Arc"
        case noArc
        
        init(_ from: String) {
                switch(from) {
                    case "Front Arc": self = .frontArc
                    case "Single Turret Arc": self = .singleTurretArc
                    case "Bullseye Arc": self = .bullseyeArc
                    case "Full Front Arc": self = .fullFrontArc
                    case "Double Turret Arc": self = .doubleTurretArc
                    case "Rear Arc": self = .rearArc
                    default: self = .noArc
                }
            }
        
        mutating func set(from: String) {
            switch(from) {
                case "Front Arc": self = .frontArc
                case "Single Turret Arc": self = .singleTurretArc
                case "Bullseye Arc": self = .bullseyeArc
                case "Full Front Arc": self = .fullFrontArc
                case "Double Turret Arc": self = .doubleTurretArc
                case "Rear Arc": self = .rearArc
                default: self = .noArc
            }
        }
        
        var symbol: String {
            get {
                switch(self) {
                    case .frontArc: return "{"
                    case .singleTurretArc: return "p"
                    case .bullseyeArc: return "}"
                    case .fullFrontArc: return "~"
                    case .doubleTurretArc: return "q"
                    case .rearArc: return "|"
                    case .noArc: return ""
                }
            }
        }
    }
    
    var firingArcs: [FiringArc] {
        get {
            let stats: [Stat] = self.stats.filter{ $0.type == "attack"}
            
            let arcs: [FiringArc] = stats.map{
                let arc = $0.arc
                let value = $0.value
                let firingArc = FiringArc(type: arc, value: value)
                return firingArc
            }
            
            return arcs
        }
    }

    var arcStats: Int {
        let stats: [Stat] = self.stats.filter{ $0.type == "attack"}
            
            if (stats.count > 0) {
                return stats[0].value
            } else {
                return 0
            }
    }
    
    var hullStats: Int {
        let stats: [Stat] = self.stats.filter{ $0.type == "hull"}
        
        if (stats.count > 0) {
            return stats[0].value
        } else {
            return 0
        }
    }
    
    var shieldStats: Int {
        let stats: [Stat] = self.stats.filter{ $0.type == "shields"}
        
        if (stats.count > 0) {
            return stats[0].value
        } else {
            return 0
        }
    }
    
    func selectedPilot(pilotId: String) -> Pilot? {
        let foundPilots = pilots.filter{ $0.xws == pilotId }
        
        if foundPilots.count > 0 {
            return foundPilots[0].asPilot()
        }
        
        print("Ship.selectedPilot pilot not found \(pilotId)")
        return nil
    }
    
    /* Standard Loadout support
     
     "shipStats": [
             { "arc": "Front Arc", "type": "attack", "value": 2 },
             { "type": "agility", "value": 3 },
             { "type": "hull", "value": 3 },
             { "type": "shields", "value": 3 }
           ]
     
     standardLoadout    shipStats   Result
     =====================================
     nil                nil         Use ship.stats
     nil                X           Use pilot.shipStats
     X                  nil         Use ship.stats
     X                  X           Use pilot.shipStats
     
     if (pilot.shipStats == nil) {
        // Use ship.stats
     } else {
        // Use pilot.shipStats
     }
     
     */
    func pilotShields(pilotId: String) -> Int {
        func getStandardLoadoutStat(pilotId: String, type: String) -> Int {
            let foundPilots = pilots.filter{ $0.xws == pilotId }
            
            if foundPilots.count > 0 {
                guard let sl = foundPilots[0].standardLoadout else {
                    return 0
                }
                
                guard let shipStats = foundPilots[0].shipStats else {
                    return 0
                }
                
                let stats: [Stat] = shipStats.filter{ $0.type == "shields"}
                
                if (stats.count > 0) {
                    return stats[0].value
                } else {
                    return 0
                }
            } else {
                return 0
            }
        }
        
        return getStandardLoadoutStat(pilotId: pilotId, type: "shields")
    }

    // Supports pilot shipStats for standard loadout pilot
    /*
     
     */
    func getShipStat(by pilotId: String, and type: String) -> Int {
        func getStat(by type: String, stats: [Stat]) -> Int {
            let statsWithType: [Stat] = stats.filter{ $0.type == type }
            return (statsWithType.count > 0) ? statsWithType[0].value : 0
        }
        
        // get all of the pilotShipStats
        guard let pilotShipStats = pilotShipStats(pilotId: pilotId) else {
            // No pilot ship stats
            return getStat(by: type, stats: self.stats)
        }
        
        // we have pilot ship stats
        
        // if we have pilot ship stat matching this type, return it,
        // otherwise fall back and check if self.stats has a stat matching this type
        /*
           For the case where the standard loadout card only grants an extra shield but no other stats
           are called out, so we use the self.stats to get the hull, agility, etc...
         */
        return getStat(by: type, stats: pilotShipStats)
    }
    
    /* "standardLoadout": ["hate", "ionmissiles", "afterburners"] */
    func pilotStandardLoadoutUpgrades(pilotId: String) -> [String]? {
        let foundPilots = pilots.filter{ $0.xws == pilotId }
        
        guard foundPilots.count > 0 else {
            return nil
        }
        
        let pilot = foundPilots[0]
        return pilot.standardLoadout
    }
    
    func pilotShipStats(pilotId: String) -> [Stat]? {
        let foundPilots = pilots.filter{ $0.xws == pilotId }
        
        // No pilots found, return empty array
        guard foundPilots.count > 0 else {
            return nil
        }
        
        let pilot = foundPilots[0]
        
        guard let pilotShipStats = pilot.shipStats else {
            return nil
        }
        
        guard pilotShipStats.count > 0 else {
            return nil
        }
        
        return pilotShipStats
        
        /*
        if pilot.shipStats == nil {
            return nil
        } else {
            return (pilot.shipStats!.count > 0) ? pilot.shipStats : nil
        }
        */
    }
    
    func pilotForce(pilotId: String) -> Int {
        guard let pilot = selectedPilot(pilotId: pilotId) else {
            return 0
        }
        
        guard let force = pilot.force?.value else {
            return 0
        }
        
        return force
    }
    
    func pilotCharge(pilotId: String) -> Int {
        guard let pilot = selectedPilot(pilotId: pilotId) else {
            return 0
        }
        
        guard let charge = pilot.charges?.value else {
            return 0
        }
        
        return charge
    }
    
    func getPilot(pilotName: String) -> Pilot {
        var pilot: Pilot = self.pilots.filter{ $0.xws == pilotName }[0].asPilot()
        
        /// Update image to point to "https://pakirby1.github.io/Images/XWing/Pilots/{pilotName}.png
        pilot.image = ImageUrlTemplates.buildPilotUrl(xws: pilotName)
        
        return pilot
    }
}

struct ShipPilot: Identifiable, Equatable {
    let id = UUID()
    let ship: Ship
    let upgrades: [Upgrade]
    let points: Int
    let pilotState: PilotState
    
    static func ==(lhs: ShipPilot, rhs: ShipPilot) -> Bool {
        return lhs.id == rhs.id
    }

    enum Status {
        case full
        case half(Int)
        case destroyed(Int)
    }
}

extension ShipPilot: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ShipPilot {
    var shipName: String { ship.xws }
    var pilotName: String { ship.pilots[0].xws }
    
    // FIX ME: Too much deserialize???
    var pilotStateData: PilotStateData? {
        if let json = self.pilotState.json {
            return PilotStateData.deserialize(jsonString: json)
        }

        return nil
    }
    
    var pilot: Pilot {
        return ship.pilots[0].asPilot()
    }
    
    var halfPoints: Int {
        return points / 2
    }
    
    var threshold: Int {
        guard let data = pilotStateData else { return 0 }
        
        return data.halfHealth
    }
    
    var selectedManeuver: String {
        guard let data = pilotStateData else { return "" }
        
        return data.selected_maneuver
    }
    
    var totalActiveHealth: Int {
        guard let data = pilotStateData else { return 0 }
        let active = data.hull_active + data.shield_active
        
        return active
    }
    
    var totalInactiveHealth: Int {
        guard let data = pilotStateData else { return 0 }
        let inactive = data.hull_inactive + data.shield_inactive
        
        return inactive
    }
    
    var healthStatus: ShipPilot.Status {
        if (totalActiveHealth == 0) {
            return .destroyed(points)
        } else if (totalInactiveHealth) >= threshold {
            return .half(halfPoints)
        }
        
        return .full
    }
}

struct TieInInterceptor : ShipProtocol {
    let dial: [String] = [
        "1TW",
        "1YW",
        "2TB",
        "2BB",
        "2FB",
        "2NB",
        "2YB",
        "3LR",
        "3TW",
        "3BW",
        "3FB",
        "3NW",
        "3YW",
        "3PR",
        "4FB",
        "4KR",
        "5FW"
    ]
}
