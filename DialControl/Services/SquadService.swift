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
    
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
}

protocol SquadServiceProtocol : class {
    var alertText: String { get set }
    var moc: NSManagedObjectContext { get }
    func loadSquad(jsonString: String) -> Squad
    func saveSquad(jsonString: String, name: String, isFavorite: Bool) -> SquadData
    func updateSquad(squadData: SquadData)
    func deleteSquad(squadData: SquadData)
    func loadSquadsList(callback: ([SquadData]) -> Void)
    func loadSquadsListRx() -> AnyPublisher<[SquadData], Error>
}
    
extension SquadServiceProtocol {
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
    
    func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString) { [weak self] errorString in
            self?.alertText = errorString
        }
    }
    
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
        let count = self.shipPilots.count
        logMessage("damagedPoints count: \(count)")
        
        let points: [Int] = self.shipPilots.map { shipPilot in
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
