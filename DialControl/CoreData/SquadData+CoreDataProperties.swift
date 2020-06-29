//
//  SquadData+CoreDataProperties.swift
//  DialControl
//
//  Created by Phil Kirby on 6/29/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
//

import Foundation
import CoreData


extension SquadData {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<SquadData> {
//        return NSFetchRequest<SquadData>(entityName: "SquadData")
//    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var json: String?

}
