//
//  Ship.swift
//  DialControl
//
//  Created by Phil Kirby on 3/14/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation


// E = Left Talon, column 0
// L = Left Sloop, column 1
// T = Left Turn, column 2
// B = Left Bank, column 3
// A = Left Reverse, column 4
// O = Stop, column 5
// S = Reverse, column 6
// F = Forward, column 7
// R = Right Talon, column 8
// P = Right Sloop, column 9
// Y = Right Turn, column 10
// N = Right Bank, column 11
// D = Right Reverse, column 12
// K = Koigran Turn, column 13
// "dial": [
//   "1TW",
//   "1YW",
//   "2TB",
//   "2BB",
//   "2FB",
//   "2NB",
//   "2YB",
//   "3LR",
//   "3TW",
//   "3BW",
//   "3FB",
//   "3NW",
//   "3YW",
//   "3PR"
// ]

let shipJSON = """
{
  "name": "TIE/in Interceptor",
  "xws": "tieininterceptor",
  "ffg": 41,
  "size": "Small",
  "dial": [
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
    "3PR"
  ],
  "dialCodes": [
    "TI"
  ],
  "faction": "Galactic Empire",
  "stats": [
    { "arc": "Front Arc", "type": "attack", "value": 3 },
    { "type": "agility", "value": 3 },
    { "type": "hull", "value": 3 }
  ],
  "actions": [
    { "difficulty": "White", "type": "Focus" },
    { "difficulty": "White", "type": "Evade" },
    { "difficulty": "White", "type": "Barrel Roll" },
    { "difficulty": "White", "type": "Boost" }
  ],
  "icon": "https://sb-cdn.fantasyflightgames.com/ship_types/I_TIEInterceptor.png",
  "pilots": [
    {
      "name": "Alpha Squadron Pilot",
      "initiative": 1,
      "limited": 0,
      "cost": 31,
      "xws": "alphasquadronpilot",
      "text": "Sienar Fleet Systems designed the TIE interceptor with four wing-mounted laser cannons, a dramatic increase in firepower over its predecessors.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_106.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_106.jpg",
      "ffg": 106,
      "hyperspace": false
    },
    {
      "name": "Saber Squadron Ace",
      "initiative": 4,
      "limited": 0,
      "cost": 36,
      "xws": "sabersquadronace",
      "text": "Led by Baron Soontir Fel, the pilots of Saber Squadron are among the Empire's best. Their TIE interceptors are marked with red stripes to designate pilots with at least ten confirmed kills.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_105.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_105.jpg",
      "ffg": 105,
      "hyperspace": false
    },
    {
      "name": "Soontir Fel",
      "caption": "Ace of Legend",
      "initiative": 6,
      "limited": 1,
      "cost": 53,
      "xws": "soontirfel",
      "ability": "At the start of the Engagement Phase, if there is an enemy ship in your [Bullseye Arc], gain 1 focus token.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_103.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_103.jpg",
      "ffg": 103,
      "hyperspace": false
    },
    {
      "name": "Turr Phennir",
      "caption": "Ambitious Ace",
      "initiative": 4,
      "limited": 1,
      "cost": 42,
      "xws": "turrphennir",
      "ability": "After you perform an attack, you may perform a [Barrel Roll] or [Boost] action, even if you are stressed.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_104.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_104.jpg",
      "ffg": 104,
      "hyperspace": false
    }
  ]
}
"""

protocol ShipProtocol {
    var dial: [String] { get }
}

// Best way to handle missing keys in JSON
/// https://stackoverflow.com/questions/44575293/with-jsondecoder-in-swift-4-can-missing-keys-use-a-default-value-instead-of-hav
/*
 "stats": [
     { "type": "attack", "arc": "Bullseye Arc", "value": 3 },
     { "type": "attack", "arc": "Front Arc", "value": 2 },
     { "type": "agility", "value": 3 },
     { "type": "hull", "value": 3 },
     { "type": "shields", "value": 0 }
   ]
 */
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
    //    "force": { "value": 3, "recovers": 1, "side": ["dark"] },
    let value: Int
    let recovers: Int
//    let side: [String]
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
    
    private var _text: String?
    private var _force: Force?
    private var _charges: Charges?
    private var _shipAbility: ShipAbility?
    private var _slots: [Slot]?
    private var _artwork: String?
    
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
    /*
     ([DialControl.Stat]) $R2 = 4 values {
       [0] = {
         type = "attack"
         value = 3
         _arc = "Front Arc"
       }
       [1] = {
         type = "agility"
         value = 3
         _arc = nil
       }
       [2] = {
         type = "hull"
         value = 2
         _arc = nil
       }
       [3] = {
         type = "shields"
         value = 2
         _arc = nil
       }
     }

     "Front Arc"
     "Single Turret Arc"
     "Bullseye Arc"
     "Full Front Arc"
     "Double Turret Arc"
     "Rear Arc"
     */
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
        if points.isMultiple(of: 2) {
            return points / 2
        } else {
            return (points + 1) / 2
        }
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
