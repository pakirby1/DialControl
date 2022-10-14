//
//  ShipService.swift
//  DialControl
//
//  Created by Phil Kirby on 2/19/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine

class ShipService {
    static func getShips(squad: Squad, squadData: SquadData) -> [ShipPilot] {
        let pilotStates = squadData.pilotStateArray.sorted(by: { $0.pilotIndex < $1.pilotIndex })
        _ = pilotStates.map{ print("pilotStates[\($0.pilotIndex)] id:\(String(describing: $0.id))") }
        
        let zipped: Zip2Sequence<[SquadPilot], [PilotState]> = zip(squad.pilots, pilotStates)
        
        _ = zipped.map{ print("\(String(describing: $0.0.name)): \($0.1)")}
        
        let ret = zipped.map{
            global_getShip(squad: squad, squadPilot: $0.0, pilotState: $0.1)
        }
        
        ret.printAll(tag: "PAK_DialStatus getShips()")
        
        return ret
    }
}

protocol ShipServiceProtocol {
    func getShips(squad: Squad, squadData: SquadData) -> [ShipPilot]
}
