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
    lazy var shipPilots: [ShipPilot] = {
        return getShips()
    }()
    
    lazy var squad: Squad = {
        return Squad.loadSquad(jsonString: self.json!)
    }()
}
