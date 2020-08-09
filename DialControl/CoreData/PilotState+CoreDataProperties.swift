//
//  PilotState+CoreDataProperties.swift
//  DialControl
//
//  Created by Phil Kirby on 8/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
//

import Foundation
import CoreData


extension PilotState {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PilotState> {
        return NSFetchRequest<PilotState>(entityName: "PilotState")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var squadID: UUID?
    @NSManaged public var json: String?

}
