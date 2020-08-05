//
//  squad.swift
//  DialControl
//
//  Created by Phil Kirby on 3/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

let squadJSON = """
{
    "description":"",
    "faction":"galacticempire",
    "name":"OutmaneuverSoontirVaderSnapDuchess",
    "pilots":
    [
        {
            "id":"soontirfel",
            "name":"soontirfel",
            "points":69,
            "ship":"tieininterceptor",
            "upgrades":
            {
                "talent":["outmaneuver"],
                "modification":["hullupgrade","targetingcomputer"]
            }
        },
        {
            "id":"darthvader",
            "name":"darthvader",
            "points":75,
            "ship":"tieadvancedx1",
            "upgrades":
            {
                "sensor":["firecontrolsystem"],
                "modification":["afterburners"]
            }
        },
        {
            "id":"duchess",
            "name":"duchess",
            "points":49,
            "ship":"tieskstriker",
            "upgrades":
            {
                "talent":["snapshot"]
            }
        }
    ],
    "points":193,
    "vendor":
    {
        "yasb":
        {
            "builder":"Yet Another Squad Builder 2.0",
            "builder_url":"https://raithos.github.io/",
            "link":"https://raithos.github.io/?f=Galactic%20Empire&d=v8ZsZ200Z179X126W164W249Y173XW113WW105Y211X256WWW&sn=OutmaneuverSoontirVaderSnapDuchess&obs="
        }
    },
    "version":"2.0.0"
}
"""

let New_squadJSON = """
{
  "description": "",
  "faction": "rebelalliance",
  "name": "CassianAPBraylenTen",
  "pilots": [
    {
      "id": "cassianandor",
      "name": "cassianandor",
      "points": 59,
      "ship": "ut60duwing",
      "upgrades": {
        "crew": [
          "k2so"
        ],
        "configuration": [
          "pivotwing"
        ]
      }
    },
    {
      "id": "ap5",
      "name": "ap5",
      "points": 32,
      "ship": "sheathipedeclassshuttle"
    },
    {
      "id": "braylenstramm",
      "name": "braylenstramm",
      "points": 55,
      "ship": "asf01bwing",
      "upgrades": {
        "cannon": [
          "tractorbeam",
          "jammingbeam"
        ]
      }
    },
    {
      "id": "tennumb",
      "name": "tennumb",
      "points": 53,
      "ship": "asf01bwing",
      "upgrades": {
        "cannon": [
          "autoblasters",
          "jammingbeam"
        ],
        "configuration": [
          "stabilizedsfoils"
        ]
      }
    }
  ],
  "points": 199,
  "vendor": {
    "yasb": {
      "builder": "Yet Another Squad Builder 2.0",
      "builder_url": "https://raithos.github.io/",
      "link": "https://raithos.github.io/?f=Rebel%20Alliance&d=v8ZsZ200Z32XWW314WWW140Y72XWWWWY73XWW13W12WWWY74XWW232W12WWW313&sn=CassianAPBraylenTen&obs="
    }
  },
  "version": "2.0.0"
}
"""

struct SquadPilotUpgrade: Codable {
    var astromechs: [String] { return _astromech ?? [] }
    var cannons: [String] { return _cannon ?? [] }
    var cargos: [String] { return _cargo ?? [] }
    var commands: [String] { return _command ?? [] }
    var configurations: [String] { return _configuration ?? [] }
    var crews: [String] { return _crew ?? [] }
    var devices: [String] { return _device ?? [] }
    var forcepowers: [String] { return _forcepower ?? [] }
    var gunners: [String] { return _gunner ?? [] }
    var hardpoints: [String] { return _hardpoint ?? [] }
    var illicits: [String] { return _illicit ?? [] }
    var missiles: [String] { return _missile ?? [] }
    var modifications: [String] { return _modification ?? [] }
    var sensors: [String] { return _sensor ?? [] }
    var tacticalrelays: [String] { return _tacticalrelay ?? [] }
    var talents: [String] { return _talent ?? [] }
    var teams: [String] { return _team ?? [] }
    var techs: [String] { return _tech ?? [] }
    var titles: [String] { return _title ?? [] }
    var torpedos: [String] { return _torpedo ?? [] }
    var turrets: [String] { return _turret ?? [] }

    private var _astromech: [String]?
    private var _cannon: [String]?
    private var _cargo: [String]?
    private var _command: [String]?
    private var _configuration: [String]?
    private var _crew: [String]?
    private var _device: [String]?
    private var _forcepower: [String]?
    private var _gunner: [String]?
    private var _hardpoint: [String]?
    private var _illicit: [String]?
    private var _missile: [String]?
    private var _modification: [String]?
    private var _sensor: [String]?
    private var _tacticalrelay: [String]?
    private var _talent: [String]?
    private var _team: [String]?
    private var _tech: [String]?
    private var _title: [String]?
    private var _torpedo: [String]?
    private var _turret: [String]?

    enum CodingKeys: String, CodingKey {
        case _astromech = "astromech"
        case _cannon = "cannon"
        case _cargo = "cargo"
        case _command = "command"
        case _configuration = "configuration"
        case _crew = "crew"
        case _device = "device"
        case _forcepower = "forcepower"
        case _gunner = "gunner"
        case _hardpoint = "hardpoint"
        case _illicit = "illicit"
        case _missile = "missile"
        case _modification = "modification"
        case _sensor = "sensor"
        case _tacticalrelay = "tacticalrelay"
        case _talent = "talent"
        case _team = "team"
        case _tech = "tech"
        case _title = "title"
        case _torpedo = "torpedo"
        case _turret = "turret"
    }
}

struct SquadPilot: Codable, Identifiable {
    let id: String
    let name: String
    let points: Int
    let ship: String
    var upgrades: SquadPilotUpgrade? { return _upgrades ?? nil }
    
    private var _upgrades: SquadPilotUpgrade?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case points = "points"
        case ship = "ship"
        case _upgrades = "upgrades"
    }
}

struct SquadVendorDetails: Codable {
    let builder: String
    let builder_url: String
}

struct SquadVendor: Codable {
    let yasb: SquadVendorDetails
}

struct Squad: Codable, JSONSerialization {
    let description: String
    let faction: String
    let name: String
    let pilots: [SquadPilot]
    let points: Int
    let vendor: SquadVendor
    let version: String
    
    var Myfaction: Faction? {
        print(faction)
        return Faction(rawValue: self.faction)
    }
    
    static var emptySquad: Squad {
        get {
            return Squad(description: "Invalid",
                         faction: "",
                         name: "Empty Squad",
                         pilots: [],
                         points: 0,
                         vendor: SquadVendor.init(yasb: SquadVendorDetails.init(builder: "", builder_url: "")),
                         version: "0.0")
        }
    }
    
    static func serializeJSON(jsonString: String,
                              callBack: ((String) -> ())? = nil) -> Squad {
        func handleError(errorString: String) {
            print(errorString)
            
            if let cb = callBack {
                cb(errorString)
            }
        }
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let squad = try decoder.decode(Squad.self, from: jsonData)
            return squad
        } catch let DecodingError.dataCorrupted(context) {
            let errorString: String = context.debugDescription
            handleError(errorString: errorString)
        } catch {
            let errorString: String = "error: \(error)"
            handleError(errorString: errorString)
        }
        
        return Squad.emptySquad
    }
}

extension Squad: Equatable {
    static func ==(lhs: Squad, rhs: Squad) -> Bool {
        return true
    }
}
