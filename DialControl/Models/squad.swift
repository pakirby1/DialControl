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
    var talents: [String] { return _talent ?? [] }
    var modifications: [String] { return _modification ?? [] }
    var sensors: [String] { return _sensor ?? [] }
    
    private var _sensor: [String]?
    private var _talent: [String]?
    private var _modification: [String]?
    
    enum CodingKeys: String, CodingKey {
        case _sensor = "sensor"
        case _talent = "talent"
        case _modification = "modification"
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
    
    static func serializeJSON(jsonString: String) -> Squad {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let squad = try! decoder.decode(Squad.self, from: jsonData)
        return squad
    }
}
