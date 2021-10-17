//
//  SquadData+CoreDataClass.swift
//  DialControl
//
//  Created by Phil Kirby on 6/29/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
//

import Foundation
import CoreData


public class SquadData: NSManagedObject {
    var shipPilots: [ShipPilot] = []
    
//    lazy var shipPilots: [ShipPilot] = {
////        return getShips()
//        return SquadCardViewModel.getShips(squad: squad, squadData: self)
//    }()
    
    lazy var squad: Squad = {
        return Squad.loadSquad(jsonString: self.json!)
    }()
}

extension SquadData: DamagedSquadRepresenting {
    
}
