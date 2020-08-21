//
//  Upgrade.swift
//  DialControl
//
//  Created by Phil Kirby on 4/14/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

let modificationsUpgradesJSON = """
[
  {
    "name": "Ablative Plating",
    "limited": 0,
    "xws": "ablativeplating",
    "sides": [
      {
        "title": "Ablative Plating",
        "type": "Modification",
        "ability": "Before you would suffer damage from an obstacle or from a friendly bomb detonating, you may spend 1 [Charge]. If you do, prevent 1 damage.",
        "slots": ["Modification"],
        "charges": { "value": 2, "recovers": 0 },
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_68.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_68.jpg",
        "ffg": 292
      }
    ],
    "cost": { "value": 6 },
    "restrictions": [{ "sizes": ["Medium", "Large"] }],
    "hyperspace": false
  },
  {
    "name": "Advanced SLAM",
    "limited": 0,
    "xws": "advancedslam",
    "sides": [
      {
        "title": "Advanced SLAM",
        "type": "Modification",
        "ability": "After you perform a [SLAM] action, if you fully executed the maneuver, you may perform a white action on your action bar, treating that action as red.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_69.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_69.jpg",
        "ffg": 293
      }
    ],
    "cost": { "value": 3 },
    "restrictions": [{ "action": { "type": "SLAM", "difficulty": "White" } }],
    "hyperspace": true
  },
  {
    "name": "Afterburners",
    "limited": 0,
    "xws": "afterburners",
    "sides": [
      {
        "title": "Afterburners",
        "type": "Modification",
        "ability": "After you fully execute a speed 3-5 maneuver, you may spend 1 [Charge] to perform a [Boost] action, even while stressed.",
        "slots": ["Modification"],
        "charges": { "value": 2, "recovers": 0 },
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_70.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_70.jpg",
        "ffg": 294
      }
    ],
    "cost": { "value": 6 },
    "restrictions": [{ "sizes": ["Small"] }],
    "hyperspace": false
  },
  {
    "name": "Electronic Baffle",
    "limited": 0,
    "xws": "electronicbaffle",
    "sides": [
      {
        "title": "Electronic Baffle",
        "type": "Modification",
        "ability": "During the End Phase, you may suffer 1 [Hit] damage to remove 1 red token.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_71.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_71.jpg",
        "ffg": 295
      }
    ],
    "cost": { "value": 2 },
    "hyperspace": false
  },
  {
    "name": "Engine Upgrade",
    "limited": 0,
    "xws": "engineupgrade",
    "sides": [
      {
        "title": "Engine Upgrade",
        "type": "Modification",
        "text": "Large military forces such as the Galactic Empire have standardized engines, but individual pilots and small organizations often replace the power couplings, add thrusters, or use high-performance fuel to get extra push out of their engines.",
        "slots": ["Modification"],
        "actions": [{ "type": "Boost", "difficulty": "White" }],
        "grants": [
          {
            "type": "action",
            "value": { "type": "Boost", "difficulty": "White" }
          }
        ],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_72.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_72.jpg",
        "ffg": 296
      }
    ],
    "cost": {
      "variable": "size",
      "values": { "Small": 2, "Medium": 4, "Large": 7 }
    },
    "restrictions": [{ "action": { "type": "Boost", "difficulty": "Red" } }],
    "hyperspace": true
  },
  {
    "name": "Hull Upgrade",
    "limited": 0,
    "xws": "hullupgrade",
    "sides": [
      {
        "title": "Hull Upgrade",
        "type": "Modification",
        "text": "For those who cannot afford an enhanced shield generator, bolting additional plates onto the hull of a ship can serve as an adequate substitute.",
        "slots": ["Modification"],
        "grants": [{ "type": "stat", "value": "hull", "amount": 1 }],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_73.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_73.jpg",
        "ffg": 297
      }
    ],
    "cost": {
      "variable": "agility",
      "values": { "0": 2, "1": 3, "2": 5, "3": 7 }
    },
    "hyperspace": true
  },
  {
    "name": "Munitions Failsafe",
    "limited": 0,
    "xws": "munitionsfailsafe",
    "sides": [
      {
        "title": "Munitions Failsafe",
        "type": "Modification",
        "ability": "While you perform a [Torpedo] or [Missile] attack, after rolling attack dice, you may cancel all dice results to recover 1 [Charge] you spent as a cost for the attack.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_74.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_74.jpg",
        "ffg": 298
      }
    ],
    "cost": { "value": 1 },
    "hyperspace": true
  },
  {
    "name": "Shield Upgrade",
    "limited": 0,
    "xws": "shieldupgrade",
    "sides": [
      {
        "title": "Shield Upgrade",
        "type": "Modification",
        "text": "Deflector shields are a substantial line of defense on most starships beyond the lightest fighters. While enhancing a ship's shield capacity can be costly, all but the most confident or reckless pilots see the value in this sort of investment.",
        "alt": [
          {
            "image": "https://images-cdn.fantasyflightgames.com/filer_public/2a/c1/2ac1eae4-dd25-4807-b09e-df97786a2093/g18x3-shield-upgrade-2.png",
            "source": "Season Three 2018"
          }
        ],
        "slots": ["Modification"],
        "grants": [{ "type": "stat", "value": "shields", "amount": 1 }],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_75.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_75.jpg",
        "ffg": 299
      }
    ],
    "cost": {
      "variable": "agility",
      "values": { "0": 3, "1": 4, "2": 6, "3": 8 }
    },
    "hyperspace": false
  },
  {
    "name": "Static Discharge Vanes",
    "limited": 0,
    "xws": "staticdischargevanes",
    "sides": [
      {
        "title": "Static Discharge Vanes",
        "type": "Modification",
        "ability": "Before you would gain 1 ion or jam token, if you are not stressed, you may choose another ship at range 0-1 and gain 1 stress token. If you do, the chosen ship gains that ion or jam token instead, then you suffer 1 [Hit] damage.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_76.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_76.jpg",
        "ffg": 300
      }
    ],
    "cost": { "value": 6 },
    "hyperspace": false
  },
  {
    "name": "Stealth Device",
    "limited": 0,
    "xws": "stealthdevice",
    "sides": [
      {
        "title": "Stealth Device",
        "type": "Modification",
        "ability": "While you defend, if your [Charge] is active, roll 1 additional defense die. After you suffer damage, lose 1 [Charge].",
        "slots": ["Modification"],
        "charges": { "value": 1, "recovers": 0 },
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_77.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_77.jpg",
        "ffg": 301
      }
    ],
    "cost": {
      "variable": "agility",
      "values": { "0": 3, "1": 4, "2": 6, "3": 8 }
    },
    "hyperspace": false
  },
  {
    "name": "Tactical Scrambler",
    "limited": 0,
    "xws": "tacticalscrambler",
    "sides": [
      {
        "title": "Tactical Scrambler",
        "type": "Modification",
        "ability": "While you obstruct an enemy ship's attack, the defender rolls 1 additional defense die.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_78.png",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_U_78.jpg",
        "ffg": 302
      }
    ],
    "cost": { "value": 2 },
    "restrictions": [{ "sizes": ["Medium", "Large"] }],
    "hyperspace": false
  },
  {
    "name": "Impervium Plating",
    "limited": 0,
    "xws": "imperviumplating",
    "sides": [
      {
        "title": "Impervium Plating",
        "type": "Modification",
        "ability": "Before you would be dealt a faceup Ship damage card, you may spend 1 [Charge] to discard it instead.",
        "charges": { "value": 2, "recovers": 0 },
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/93e0fe1b2931944d128126b854c4ad33.png",
        "ffg": 534,
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/20769de45863e2bbb180f05e6ed1e0e3.jpg"
      }
    ],
    "restrictions": [{ "ships": ["belbullab22starfighter"] }],
    "hyperspace": false,
    "cost": { "value": 4 }
  },
  {
    "name": "Synchronized Console",
    "xws": "synchronizedconsole",
    "limited": 0,
    "sides": [
      {
        "title": "Synchronized Console",
        "type": "Modification",
        "ability": "After you perform an attack, you may choose a friendly ship at range 1 or a friendly ship with the Synchronized Console upgrade at range 1-3 and spend a lock you have on the defender. If you do, the friendly ship you chose may acquire a lock on the defender.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/e3e5bd38f39f904fbaaa75293e56fb38.png",
        "ffg": 554,
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/f105bb42b6d3500c300e48ab695c1647.jpg"
      }
    ],
    "restrictions": [
      { "factions": ["Galactic Republic"] },
      { "action": { "type": "Lock", "difficulty": "White" } }
    ],
    "hyperspace": false,
    "cost": { "value": 1 }
  },
  {
    "name": "Spare Parts Canisters",
    "limited": 0,
    "xws": "sparepartscanisters",
    "sides": [
      {
        "title": "Spare Parts Canisters",
        "type": "Modification",
        "ability": "Action: Spend 1 [Charge] to recover 1 charge on one of your equipped [Astromech] upgrades. Action: Spend 1 [Charge] to drop 1 spare parts, then break all locks assigned to you.",
        "charges": { "value": 1, "recovers": 0 },
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/79d9f2b2bc32bd78ab67dc82eece696a.png",
        "ffg": 550,
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/a61b812e2e74fab5435c9684462cd9d7.jpg"
      }
    ],
    "restrictions": [{ "equipped": ["Astromech"] }],
    "hyperspace": true,
    "cost": { "value": 4 }
  },
  {
    "name": "Delayed Fuses",
    "limited": 0,
    "xws": "delayedfuses",
    "sides": [
      {
        "title": "Delayed Fuses",
        "type": "Modification",
        "ability": "After you drop, launch, or place a bomb or mine, you may place 1 fuse marker on that device.",
        "slots": ["Modification"],
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/4572ece39224eeaf2dfce2770b96f919.png",
        "ffg": 592,
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/453d2de1f5059d0e6eb7884a4bf7986b.jpg"
      }
    ],
    "hyperspace": true,
    "cost": { "value": 1 }
  },
  {
    "name": "Angled Deflectors",
    "limited": 0,
    "xws": "angleddeflectors",
    "hyperspace": true,
    "cost": {
      "variable": "agility",
      "values": { "0": 9, "1": 6, "2": 3, "3": 3 }
    },
    "restrictions": [{ "sizes": ["Small", "Medium"] }],
    "sides": [
      {
        "text": "Starfighter shields often have manual overrides that allow them to be angled for increased front or rear protection. However, doing so leaves the ship exposed if the pilot's situational awareness falters.",
        "title": "Angled Deflectors",
        "type": "Modification",
        "slots": ["Modification"],
        "restrictions": [{ "sizes": ["Small", "Medium"] }],
        "grants": [
          { "type": "stat", "value": "shields", "amount": -1 },
          {
            "type": "action",
            "value": { "type": "Reinforce", "difficulty": "White" }
          }
        ],
        "ffg": 593,
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/691b45548136b6e5fd005e7797ae53d9.jpg",
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/41cf9c90abcd8ff5c668bb447967b75c.png"
      }
    ]
  },
  {
    "name": "Targeting Computer",
    "limited": 0,
    "sides": [
      {
        "ffg": 619,
        "title": "Targeting Computer",
        "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/2e8e6572a5802967220296ec22e5d8cb.jpg",
        "image": "https://sb-cdn.fantasyflightgames.com/card_images/en/619d3d56eadaada29c6602cc7cd00148.png",
        "text": "Targeting computers are standard features on many vessels, especially those designed to deliver ordnance. Some light starfighters and transport craft lack such weapons guidance, though it can be installed as an after-market modification.",
        "slots": ["Modification"],
        "type": "Modification",
        "grants": [
          {
            "type": "action",
            "value": { "type": "Lock", "difficulty": "White" }
          }
        ]
      }
    ],
    "cost": { "value": 3 },
    "hyperspace": true,
    "xws": "targetingcomputer"
  }
]
"""

/*
"stats": [
  { "arc": "Front Arc",
    "type": "attack", "value": 3 }
],
*/

import Foundation

struct GrantValue: Codable {
    let type: String
    let difficulty: String
}

struct Grant: Codable {
    var type: String { return _type ?? ""}
    var value: GrantValue?
    
    private var _type: String?
    private var _value: GrantValue?
    
    enum CodingKeys: String, CodingKey {
        case _type = "type"
//        case _value = "value"
    }
}

struct Side: Codable {
    var ffg: Int { return _ffg ?? 0 }
    var title: String { return _title ?? "" }
    var artwork: String { return _artwork ?? "" }
    var image: String { return _image ?? "" }
    var text: String { return _text ?? "" }
    var slots: [String] { return _slots ?? [] }
    var type: String { return _type ?? "" }
    var grants: [Grant] { return _grants ?? [] }
    
    private var _ffg: Int?
    private var _title: String?
    private var _artwork: String?
    private var _image: String?
    private var _text: String?
    private var _slots: [String]?
    private var _type: String?
    private var _grants: [Grant]?
    
    enum CodingKeys: String, CodingKey {
        case _text = "text"
        case _image = "image"
        case _title = "title"
        case _ffg = "ffg"
        case _grants = "grants"
        case _artwork = "artwork"
        case _slots = "slots"
        case _type = "type"
    }
}

struct Cost: Codable {
    var value: Int { return _value ?? 0 }
    
    private var _value: Int?
    
    enum CodingKeys: String, CodingKey {
        case _value = "value"
    }
}

struct Upgrade: Codable, Identifiable {
    let id = UUID()
    let name: String
    let limited: Int
    let sides: [Side]
    let cost: Cost?
    let hyperspace: Bool
    let xws: String
//    let type: String?   // Doesn't exist in json but has to be optional to set it later
}

struct Upgrades: Codable, JSONSerialization {
    let upgrades: [Upgrade]
    
    static func serializeJSON(jsonString: String) -> [Upgrade] {
        return deserialize(jsonString: jsonString)
    }
}

enum UpgradeCardEnum : CaseIterable {
    static var allCases: [UpgradeCardEnum] {
        return [.astromech(""),
        .cannon(""),
        .cargo(""),
        .command(""),
        .configuration(""),
        .crew(""),
        .device(""),
        .forcepower(""),
        .gunner(""),
        .hardpoint(""),
        .illicit(""),
        .missile(""),
        .modification(""),
        .sensor(""),
        .tacticalrelay(""),
        .talent(""),
        .team(""),
        .tech(""),
        .title(""),
        .torpedo(""),
        .turret("")]
    }

    case astromech(String)
    case cannon(String)
    case cargo(String)
    case command(String)
    case configuration(String)
    case crew(String)
    case device(String)
    case forcepower(String)
    case gunner(String)
    case hardpoint(String)
    case illicit(String)
    case missile(String)
    case modification(String)
    case sensor(String)
    case tacticalrelay(String)
    case talent(String)
    case team(String)
    case tech(String)
    case title(String)
    case torpedo(String)
    case turret(String)
}
