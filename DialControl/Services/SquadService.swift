//
//  SquadService.swift
//  DialControl
//
//  Created by Phil Kirby on 8/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import CoreData
import Combine

class SquadService: SquadServiceProtocol, ObservableObject {
    var alertText: String = ""
    var showAlert: Bool = false
    
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
}

protocol SquadServiceProtocol : class {
    var showAlert: Bool { get set }
    var alertText: String { get set }
    var moc: NSManagedObjectContext { get }
    func loadSquad(jsonString: inout String) -> Squad
    func saveSquad(jsonString: String, name: String, isFavorite: Bool) -> SquadData
    func updateSquad(squadData: SquadData)
    func deleteSquad(squadData: SquadData)
    func loadSquadsList(callback: ([SquadData]) -> Void)
    func loadSquadsListRx() -> AnyPublisher<[SquadData], Error>

    // throwing funcs
    func loadSquad_throws(jsonString: inout String) throws -> Squad
    func saveSquad_throws(jsonString: String, name: String, isFavorite: Bool) throws -> SquadData
}

enum SquadServiceProtocolError: LocalizedError {
    case jsonSerializationError(String)
    case saveSquadError(String)
    
    var errorDescription: String? {
        switch self {
            case let .jsonSerializationError(message):
                return "JSON Serialization Error: \(message)"
            
            case let .saveSquadError(message):
                return "Save Squad Error: \(message)"
        }
    }
}

extension SquadServiceProtocol {
    func loadSquad_throws(jsonString: inout String) throws -> Squad {
        func handleError(errorString: String) throws -> Void {
            self.alertText = errorString
            self.showAlert = true
            
            throw SquadServiceProtocolError.jsonSerializationError(errorString)
        }
        
        // replace janky yasb exported to remove '-' characters.
        jsonString = jsonString
            .replacingOccurrences(of: "force-power", with: "forcepower")
            .replacingOccurrences(of: "tactical-relay", with: "tacticalrelay")
        
        return Squad.serializeJSON(jsonString: jsonString,
                                   callBack: handleError as? ((String) -> ()))
    }
    
    func saveSquad_throws(jsonString: String,
                   name: String,
                   isFavorite: Bool = false) throws -> SquadData
    {
        let squadData = SquadData(context: self.moc)
        squadData.id = UUID()
        squadData.name = name
        squadData.json = jsonString
        squadData.favorite = isFavorite
        
        do {
            try self.moc.save()
        } catch {
            throw SquadServiceProtocolError.saveSquadError(error.localizedDescription)
        }
        
        return squadData
    }
}

extension SquadServiceProtocol {
    func loadSquad(jsonString: inout String) -> Squad {
        // replace janky yasb exported to remove '-' characters.
        jsonString = jsonString
            .replacingOccurrences(of: "force-power", with: "forcepower")
            .replacingOccurrences(of: "tactical-relay", with: "tacticalrelay")
        
        return Squad.serializeJSON(jsonString: jsonString) { errorString in
            self.alertText = errorString
            self.showAlert = true
        }
    }
    
    func saveSquad(jsonString: String, name: String) -> SquadData {
        return self.saveSquad(jsonString: jsonString, name: name, isFavorite: false)
    }
    
    func saveSquad(jsonString: String,
                   name: String,
                   isFavorite: Bool = false) -> SquadData
    {
        let squadData = SquadData(context: self.moc)
        squadData.id = UUID()
        squadData.name = name
        squadData.json = jsonString
        squadData.favorite = isFavorite
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
        
        return squadData
    }
    
//    func loadSquad(jsonString: String) -> Squad {
//        return Squad.serializeJSON(jsonString: jsonString) { [weak self] errorString in
//            self?.alertText = errorString
//        }
//    }
    
    func updateSquad(squadData: SquadData) {
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
    }
    
    func deleteSquad(squadData: SquadData) {
        do {
            self.moc.delete(squadData)
            try moc.save()
        } catch {
            print(error)
        }
    }
    
    func loadSquadsList(callback: ([SquadData]) -> Void) {
        do {
            let fetchRequest = SquadData.fetchRequest()
            let fetchedObjects = try self.moc.fetch(fetchRequest) as! [SquadData]
            callback(fetchedObjects)
        } catch {
            print(error)
        }
    }
    
    func loadSquadsListRx() -> AnyPublisher<[SquadData], Error> {
        let ret = Future<[SquadData], Error> { promise in
            do {
                let fetchRequest = SquadData.fetchRequest()
                let fetchedObjects = try self.moc.fetch(fetchRequest) as! [SquadData]
                return promise(.success(fetchedObjects))
            } catch {
                print(error)
                return promise(.failure(error))
            }
        }

        return ret
            .eraseToAnyPublisher()
    }
}

protocol DamagedSquadRepresenting {
    var shipPilots: [ShipPilot] { get }
}

extension DamagedSquadRepresenting {
    var damagedPoints: Int {
        let pilots = self.shipPilots
        
        let count = pilots.count
        logMessage("PAK_damagedPoints var damagedPoints \(count)")
        
        let names = pilots.map { $0.ship.name }
        logMessage("PAK_damagedPoints names: \(names)")
        
        let points: [Int] = pilots.map { shipPilot in
            logMessage("PAK_damagedPoints ship: \(shipPilot.ship.name)")
            switch(shipPilot.healthStatus) {
            case .destroyed(let value):
                return value
            case .half(let value):
                return value
            default:
                return 0
            }
        }
        
        let sum = points.reduce(0, +)
        logMessage("damagedPoints sum: \(sum)")
        
        return sum
    }
}

extension Array where Element == ShipPilot {
    var damagedPoints: Int {
        let count = self.count
        logMessage("damagedPoints count: \(count)")
        
        let points: [Int] = self.map { shipPilot in
            switch(shipPilot.healthStatus) {
            case .destroyed(let value):
                return value
            case .half(let value):
                return value
            default:
                return 0
            }
        }
        
        return points.reduce(0, +)
    }
}

extension Array where Element == SquadData {
    mutating func setShips(data: Element) {
        return setShips(data: data) {
            return SquadService.getShips(squad: $0, squadData: $1)
        }
        
//        if let index = firstIndex(where: { $0.id == data.id}) {
//            self[index].shipPilots = SquadService.getShips(
//                squad: data.squad,
//                squadData: data)
//        }
    }
    
    // setShips(data: x) { return SquadService.getShips(squad: $0, squadData: $1) }
    mutating func setShips(data: Element, handler: (Squad, SquadData) -> [ShipPilot]) {
        if let index = firstIndex(where: { $0.id == data.id}) {
            self[index].shipPilots = handler(data.squad, data)
        }
    }
}

extension SquadService {
    static func getShips(squad: Squad, squadData: SquadData) -> [ShipPilot] {
        let pilotStates = squadData.pilotStateArray.sorted(by: { $0.pilotIndex < $1.pilotIndex })
        _ = pilotStates.map{ print("pilotStates[\($0.pilotIndex)] id:\(String(describing: $0.id))") }

        let zipped: Zip2Sequence<[SquadPilot], [PilotState]> = zip(squad.pilots, pilotStates)

        _ = zipped.map{ print("\(String(describing: $0.0.name)): \($0.1)")}

        let ret: [ShipPilot] = zipped.map{
            // Making multiple calls to getShip
            global_getShip(squad: squad, squadPilot: $0.0, pilotState: $0.1)
        }

        ret.printAll(tag: "PAK_DialStatus getShips()")

        return ret
    }
}
