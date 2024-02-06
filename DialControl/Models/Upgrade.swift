//
//  Upgrade.swift
//  DialControl
//
//  Created by Phil Kirby on 4/14/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

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
    }
}

// MARK:- LinkedGrantValue
struct LinkedGrantValue: Codable {
    let type: String
    let difficulty: String
    let linked: GrantValue
}

// MARK:- LinkedActionGrant
struct LinkedActionGrant : Codable {
    let type: String
    let value: LinkedGrantValue
}

extension LinkedActionGrant: CustomStringConvertible {
    var description: String {
        return "type: \(type) value: { \(value) }"
    }
}

// MARK:- ForceGrant
struct ForceGrant : Codable {
    let type: String
    let value: ForceValue
    let amount: Int
}

struct ForceValue : Codable {
    let side: [String]
}

extension ForceValue : CustomStringConvertible {
    var description: String {
        return "side: \(side)\n"
    }
}

extension ForceGrant : CustomStringConvertible {
    var description: String {
        return "type: \(type) value: \(value) amount: \(amount)\n"
    }
}

// MARK:- GrantElement
enum GrantElement : Codable {
    case action(ActionGrant)
    case slot(SlotGrant)
    case stat(StatGrant)
    case force(ForceGrant)
    case linkedAction(LinkedActionGrant)
    case arc(ArcGrant)
    case unknown
    
    /// "type" element in JSON is decoded directly into this enum
    enum StatType: String, Codable {
        case stat, arc, action, force, slot
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        self = .unknown
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GrantElement.StatType.self, forKey: CodingKeys.type)
        
        switch(type) {
            case .stat:
                let typeContainer = try decoder.singleValueContainer()
                if let x = try? typeContainer.decode(StatGrant.self) {
                    self = .stat(x)
                    return
                }
                
            case .arc:
                let typeContainer = try decoder.singleValueContainer()
                if let x = try? typeContainer.decode(ArcGrant.self) {
                    self = .arc(x)
                    return
                }
            
            case .action:
                let typeContainer = try decoder.singleValueContainer()
                if let x = try? typeContainer.decode(ActionGrant.self) {
                    self = .action(x)
                    return
                }
                
            case .force:
                let typeContainer = try decoder.singleValueContainer()
                if let x = try? typeContainer.decode(ForceGrant.self) {
                    self = .force(x)
                    return
                }
                
            case .slot:
                let typeContainer = try decoder.singleValueContainer()
                if let x = try? typeContainer.decode(SlotGrant.self) {
                    self = .slot(x)
                    return
                }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .action(let x):
            try container.encode(x)
        case .arc(let x):
            try container.encode(x)
        case .slot(let x):
            try container.encode(x)
        case .stat(let x):
            try container.encode(x)
        case .force(let x):
            try container.encode(x)
        case .linkedAction(let x):
            try container.encode(x)
        default:
            return
        }
    }
}

extension GrantElement: CustomStringConvertible {
    var description: String {
        switch(self) {
            case .action(let actionGrant):
                return actionGrant.description
            case .arc(let arcGrant):
                return arcGrant.description
            case .slot(let slotGrant) :
                return slotGrant.description
            case .stat(let statGrant) :
                return statGrant.description
            case .force(let forceGrant) :
                return forceGrant.description
            case .linkedAction(let linkedActionGrant) :
                return linkedActionGrant.description
            default:
                return "Unknown Grant Type"
        }
    }
}

// MARK:- ArcGrant
struct ArcGrant : Codable {
    let type: String
    let value: String
}

extension ArcGrant: CustomStringConvertible {
    var description: String {
        return "ArcGrant type: \(type) value: { \(value) }"
    }
}
// MARK:- TypeValueGrant
struct TypeValueGrant : Codable {
    let type: String
    let value: GrantValue
}

extension TypeValueGrant: CustomStringConvertible {
    var description: String {
        return "TypeValueGrant type: \(type) value: { \(value) }"
    }
}

// MARK:- ActionGrant
struct ActionGrant : Codable {
    let info: TypeValueGrant
}

extension ActionGrant: CustomStringConvertible {
    var description: String {
        return "ActionGrant info: \(info.description) }"
    }
}

// MARK:- SlotGrant
struct SlotGrant : Codable {
    let type: String
    let value: String
    let amount: Int
}

extension SlotGrant : CustomStringConvertible {
    var description: String {
        return "SlotGrant type: \(type) value: \(value) amount: \(amount)"
    }
}

// MARK:- StatGrant
struct StatGrant : Codable {
    let type: String
    let value: String
    let amount: Int
//    let arc: String
}

extension StatGrant : CustomStringConvertible {
    var description: String {
        return "StatGrant type: \(type) value: \(value) amount: \(amount)"
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
    var grants: [GrantElement] { return _grants ?? [] }
    var force: Force? { return _force ?? nil }
    var charges: Charges? { return _charges ?? nil }
    var ability: String { return _ability ?? "" }
    
    private var _ffg: Int?
    private var _title: String?
    private var _artwork: String?
    private var _image: String?
    private var _text: String?
    private var _slots: [String]?
    private var _type: String?
    private var _grants: [GrantElement]?
    private var _force: Force?
    private var _charges: Charges?
    private var _ability: String?

    enum CodingKeys: String, CodingKey {
        case _text = "text"
        case _image = "image"
        case _title = "title"
        case _ffg = "ffg"
        case _grants = "grants"
        case _artwork = "artwork"
        case _slots = "slots"
        case _type = "type"
        case _force = "force"
        case _charges = "charges"
        case _ability = "ability"
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
    var name: String { return _name ?? "" }
    var limited: Int { return _limited ?? 0 }
    var sides: [Side] { return _sides ?? [] }
    var cost: Cost? { return _cost ?? nil }
    var xws: String { return _xws ?? "" }
    var standardLoadoutOnly: Bool { return _standardLoadoutOnly ?? false }

    private var _standardLoadoutOnly: Bool?
    private var _name: String?
    private var _limited: Int?
    private var _sides: [Side]?
    private var _cost: Cost?
    private var _xws: String?

    enum CodingKeys: String, CodingKey {
        case _standardLoadoutOnly = "standardLoadoutOnly"
        case _name = "name"
        case _limited = "limited"
        case _sides = "sides"
        case _cost = "cost"
        case _xws = "xws"
    }
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
