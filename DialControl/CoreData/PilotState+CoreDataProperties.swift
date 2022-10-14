//
//  PilotState+CoreDataProperties.swift
//  DialControl
//
//  Created by Phil Kirby on 8/20/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
//

import Foundation
import CoreData


extension PilotState {
    @NSManaged public var id: UUID?
    @NSManaged public var json: String?
    @NSManaged public var pilotIndex: Int32
    @NSManaged public var squadData: SquadData?

}
