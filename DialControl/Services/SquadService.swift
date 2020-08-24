//
//  SquadService.swift
//  DialControl
//
//  Created by Phil Kirby on 8/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import CoreData

class SquadService: SquadServiceProtocol {
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
}
