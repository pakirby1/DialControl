//
//  SquadData+CoreDataProperties.swift
//  DialControl
//
//  Created by Phil Kirby on 8/20/20.
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
    @NSManaged public var json: String?
    @NSManaged public var name: String?
    
    /// way easier to use:
//    @NSManaged public var pilotState: Set<PilotState>
    
    /// than this:
    @NSManaged public var pilotState: NSSet?

}

// MARK: Generated accessors for pilotState
extension SquadData {

    @objc(addPilotStateObject:)
    @NSManaged public func addToPilotState(_ value: PilotState)

    @objc(removePilotStateObject:)
    @NSManaged public func removeFromPilotState(_ value: PilotState)

    @objc(addPilotState:)
    @NSManaged public func addToPilotState(_ values: NSSet)

    @objc(removePilotState:)
    @NSManaged public func removeFromPilotState(_ values: NSSet)

}

extension SquadData {
    func getPilotState(index: Int) -> PilotState {
        let arr = Array(pilotState as! Set<PilotState>)
        return arr[index]
    }
    
    public var pilotStateArray: [PilotState] {
        return Array(pilotState as! Set<PilotState>)
    }
}
