//
//  DIContainer.swift
//  DialControl
//
//  Created by Phil Kirby on 8/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import CoreData

class DIContainer {
    var squadService: SquadService!
    var pilotStateService: PilotStateService!
    
    func registerServices(moc: NSManagedObjectContext) {
        self.squadService = SquadService(moc: moc)
        self.pilotStateService = PilotStateService(moc: moc)
    }
}
