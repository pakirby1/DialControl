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
struct Stat: Codable {
    var arc: String { return _arc ?? "" }
    let type: String
    let value: Int
    private var _arc: String?

    enum CodingKeys: String, CodingKey {
        case _arc = "name"
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

struct Pilot: Codable {
    let name: String
    let initiative: Int
    let limited: Int
    let cost: Int
    let xws: String
    var text: String { return _text ?? "" }
    let image: String
    let shipAbility: ShipAbility
    let slots: [Slot]
    let artwork: String
    let ffg: Int
    let hyperspace: Bool
    var force: Force? { return _force ?? nil }
    var charges: Charges? { return _charges ?? nil }
    
    private var _text: String?
    private var _force: Force?
    private var _charges: Charges?
    
    enum CodingKeys: String, CodingKey {
        case _text = "text"
        case name
        case initiative
        case limited
        case cost
        case xws
        case image
        case shipAbility
        case slots
        case artwork
        case ffg
        case hyperspace
        case _force = "force"
        case _charges = "charges"
    }
}

struct Ship: Codable {
    let name: String
    var xws: String { return _xws ?? "" }
    var ffg: Int { return _ffg ?? 0 }
    var size: String { return _size ?? "" }
    var dial: [String]
    let dialCodes: [String]
    let faction: String
    let stats: [Stat]
    let actions: [Action]
    let icon: String
    var pilots: [Pilot]
    
    private var _xws: String?
    private var _ffg: Int?
    private var _size: String?
//    private var _dial: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case _xws = "xws"
        case _ffg = "ffg"
        case _size = "size"
        case dial = "dial"
        case dialCodes = "dialCodes"
        case faction = "faction"
        case stats = "stats"
        case actions = "actions"
        case icon = "icon"
        case pilots = "pilots"
    }
    
    static func serializeJSON(jsonString: String) -> Ship {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let ship = try! decoder.decode(Ship.self, from: jsonData)
        return ship
    }
}

struct ShipPilot: Identifiable {
    let id = UUID()
    let ship: Ship
    let upgrades: [Upgrade]
    let points: Int
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
