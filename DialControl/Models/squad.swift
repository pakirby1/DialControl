//
//  squad.swift
//  DialControl
//
//  Created by Phil Kirby on 3/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

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

extension SquadPilotUpgrade {
    var allUpgrades: [String] {
        return astromechs +
            cannons +
            cargos +
            commands +
            configurations +
            crews +
            devices +
            forcepowers +
            gunners +
            hardpoints +
            illicits +
            missiles +
            modifications +
            sensors +
            tacticalrelays +
            talents +
            teams +
            techs +
            titles +
            torpedos +
            turrets
    }
    
    var allUpgradeKeys: [UpgradeKey] {
        return astromechKeys +
            cannonsKeys +
            cargosKeys +
            commandsKeys +
            configurationsKeys +
            crewsKeys +
            devicesKeys +
            forcepowersKeys +
            gunnersKeys +
            hardpointsKeys +
            illicitsKeys +
            missilesKeys +
            modificationsKeys +
            sensorsKeys +
            tacticalrelaysKeys +
            talentsKeys +
            teamsKeys +
            techsKeys +
            titlesKeys +
            torpedosKeys +
            turretsKeys
    }
    
    var astromechKeys: [UpgradeKey] {
        astromechs.map { UpgradeKey(category: "astromech", xws: $0) }
    }
    
    var cannonsKeys: [UpgradeKey] {
        cannons.map { UpgradeKey(category: "cannon", xws: $0) }
    }
    
    var cargosKeys: [UpgradeKey] {
        cargos.map { UpgradeKey(category: "cargo", xws: $0) }
    }
    
    var commandsKeys: [UpgradeKey] {
        commands.map { UpgradeKey(category: "command", xws: $0) }
    }
    
    var configurationsKeys: [UpgradeKey] {
        configurations.map { UpgradeKey(category: "configuration", xws: $0) }
    }
    
    var crewsKeys: [UpgradeKey] {
        crews.map { UpgradeKey(category: "crew", xws: $0) }
    }
    
    var devicesKeys: [UpgradeKey] {
        devices.map { UpgradeKey(category: "device", xws: $0) }
    }
    
    var forcepowersKeys: [UpgradeKey] {
        forcepowers.map { UpgradeKey(category: "forcepower", xws: $0) }
    }
    
    var gunnersKeys: [UpgradeKey] {
        gunners.map { UpgradeKey(category: "gunner", xws: $0) }
    }
    
    var hardpointsKeys: [UpgradeKey] {
        hardpoints.map { UpgradeKey(category: "hardpoint", xws: $0) }
    }
    
    var illicitsKeys: [UpgradeKey] {
        illicits.map { UpgradeKey(category: "illicit", xws: $0) }
    }
    
    var missilesKeys: [UpgradeKey] {
        missiles.map { UpgradeKey(category: "missile", xws: $0) }
    }
    
    var modificationsKeys: [UpgradeKey] {
        modifications.map { UpgradeKey(category: "modification", xws: $0) }
    }
    
    var sensorsKeys: [UpgradeKey] {
        sensors.map { UpgradeKey(category: "sensor", xws: $0) }
    }
    
    var tacticalrelaysKeys: [UpgradeKey] {
        tacticalrelays.map { UpgradeKey(category: "tacticalrelay", xws: $0) }
    }
    
    var talentsKeys: [UpgradeKey] {
        talents.map { UpgradeKey(category: "talent", xws: $0) }
    }
    
    var teamsKeys: [UpgradeKey] {
        teams.map { UpgradeKey(category: "team", xws: $0) }
    }
    
    var techsKeys: [UpgradeKey] {
        techs.map { UpgradeKey(category: "tech", xws: $0) }
    }
    
    var titlesKeys: [UpgradeKey] {
        titles.map { UpgradeKey(category: "title", xws: $0) }
    }
    
    var torpedosKeys: [UpgradeKey] {
        torpedos.map { UpgradeKey(category: "torpedo", xws: $0) }
    }
    
    var turretsKeys: [UpgradeKey] {
        turrets.map { UpgradeKey(category: "turret", xws: $0) }
    }
}

struct SquadPilot: Codable, Identifiable {
    let id: String
    let points: Int
    let ship: String
    var upgrades: SquadPilotUpgrade? { return _upgrades ?? nil }
    var name: String? { return _name ?? nil }
    
    private var _upgrades: SquadPilotUpgrade?
    private var _name: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case _name = "name"
        case points = "points"
        case ship = "ship"
        case _upgrades = "upgrades"
    }
}

struct SquadVendorDetails: Codable {
    let builder: String
    let builder_url: String
    let link: String
}

struct SquadVendor: Codable {
    var yasb: SquadVendorDetails? { return _yasb ?? nil }
    var lbn: SquadVendorDetails? { return _lbn ?? nil }
    
    private var _yasb: SquadVendorDetails?
    private var _lbn: SquadVendorDetails?
    
    enum CodingKeys: String, CodingKey {
        case _yasb = "yasb"
        case _lbn = "lbn"
    }
    
    init(yasb: SquadVendorDetails?, lbn: SquadVendorDetails?) {
        self._yasb = yasb
        self._lbn = lbn
    }
    
    var description: String {
        var ret = ""
        
        if yasb != nil {
            ret = "YASB"
        } else if lbn != nil {
            ret = "LBN"
        }
        
        return ret
    }
    
    var link: String {
        var ret = ""
        
        if let y = yasb {
            ret = y.link
        } else if let l = lbn {
            ret = l.link
        }
        
        return ret
    }
}

/// https://github.com/elistevens/xws-spec
struct Squad: Codable, JSONSerialization {
    // Mandatory
    let faction: String
    let pilots: [SquadPilot]
    var shipPilots: [ShipPilot] = []
    
    // Optional
    var description: String? { return _description ?? nil }
    var name: String? { return _name ?? nil }
    var points: Int? { return _points ?? nil }
    var vendor: SquadVendor? { return _vendor ?? nil }
    var version: String
    
    private var _description: String?
    private var _name: String?
    private var _points: Int?
    private var _vendor: SquadVendor?
    
    enum CodingKeys: String, CodingKey {
        case _description = "description"
        case _name = "name"
        case _points = "points"
        case _vendor = "vendor"
        case faction = "faction"
        case pilots = "pilots"
        case version = "version"
    }
    
    var Myfaction: Faction? {
        print(faction)
        return Faction(rawValue: self.faction)
    }
    
    static var emptySquad: Squad {
        get {
            let vendor: SquadVendor = SquadVendor(yasb: nil, lbn: nil)
            
            return Squad(faction: "",
                         pilots: [],
                         version: "0.0",
                         _description: "Invalid",
                         _name: "",
                         _points: 0,
                         _vendor: vendor
                         )
        }
    }
    
    static func serializeJSON(jsonString: String,
                              callBack: ((String) throws -> Void)? = nil) -> Squad
    {
        func serializeJSON_New(jsonString: String,
                                  callBack: ((String) throws -> Void)? = nil) -> Squad
        {
            func handleError(errorString: String, callBack: (String) throws -> Void) rethrows {
                    try callBack(errorString)
            }
            
            func serializeJSON(jsonString: String) -> Result<Squad, Error> {
                let jsonData = jsonString.data(using: .utf8)!
                let decoder = JSONDecoder()
                
                do {
                    let squad = try decoder.decode(Squad.self, from: jsonData)
                    return .success(squad)
                } catch let DecodingError.dataCorrupted(context) {
                    return .failure(DecodingError.dataCorrupted(context))
                } catch {
                    return .failure(error)
                }
            }
            
            let result = serializeJSON(jsonString: jsonString)
            
            switch(result) {
                case .success(let squad):
                    return squad
                case .failure(let error):
                    let errorString: String = "error: \(error)"
                    guard let cb = callBack else { return Squad.emptySquad }
                    try? handleError(errorString: errorString, callBack: cb)
            }
            
            return Squad.emptySquad
        }
        
        func serializeJSON_Old(jsonString: String,
                                  callBack: ((String) throws -> Void)? = nil) -> Squad {
            func handleError(errorString: String, callBack: (String) throws -> Void) rethrows {
                    try callBack(errorString)
            }

            let jsonData = jsonString.data(using: .utf8)!
            let decoder = JSONDecoder()

            do {
                let squad = try decoder.decode(Squad.self, from: jsonData)
                return squad
            } catch let DecodingError.dataCorrupted(context) {
                let errorString: String = context.debugDescription

                guard let cb = callBack else { return Squad.emptySquad }
                try? handleError(errorString: errorString, callBack: cb)
            } catch {
                let errorString: String = "error: \(error)"
                guard let cb = callBack else { return Squad.emptySquad }
                try? handleError(errorString: errorString, callBack: cb)
            }

            return Squad.emptySquad
        }
        
        if(FeaturesManager.shared.isFeatureEnabled(.serializeJSON)) {
            return serializeJSON_New(jsonString: jsonString, callBack: callBack)
        } else {
            return serializeJSON_Old(jsonString: jsonString, callBack: callBack)
        }
    }

    static func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString)
    }
    
    mutating func getSquad(squadData: SquadData) -> Squad {
        if let json = squadData.json {
            logMessage("damagedPoints json: \(json)")
            let squad = Squad.loadSquad(jsonString: json)
            
            let shipPilots = SquadCardViewModel.getShips(squad: squad, squadData: squadData)
            
            self.shipPilots = shipPilots
            
            return squad
        }
        
        return Squad.emptySquad
    }
    
    mutating func setShipPilots(shipPilots: [ShipPilot]) {
        self.shipPilots = shipPilots
    }
}

extension Squad: Equatable {
    static func ==(lhs: Squad, rhs: Squad) -> Bool {
        return true
    }
}
