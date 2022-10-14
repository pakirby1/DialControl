//
//  State.swift
//  DialControl
//
//  Created by Phil Kirby on 1/13/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Combine

struct AppState {
    var uiState: UIState
    var squadState: SquadState
}

struct UIState {
    let theme: Theme = WestworldUITheme()
    var buttonBackground: Color
    var textForeground: Color
    var border: Color
}

struct SquadState {
    // collection properties
    var squadDataList: [SquadData]
    var numSquads: Int
    var squadNames : [String]
    
    // selected squad
    let points: Int
    let squadData: SquadData
    var json: String
    var squad: Squad
    var displayAsList: Bool = true
    @State var shipPilots: [ShipPilot] = []
    @State private var revealAllDials: Bool = false
    var chunkedShips : [[ShipPilot]]
    var sortedShipPilots: [ShipPilot]
    var damagedPoints: Int
    
    // selected ship
    let shipPilot: ShipPilot
    let dialRevealed: Bool
    @State var currentManeuver: String = ""
}

enum AppAction {
    case loadSquadsList
    case updateSquadsList([SquadData])
    case deleteSquad(SquadData)
    case updateSquad(SquadData)
    case refreshSquadsList
    case updateFavorites(Bool)
    case loadSquad(String)
    case getShips(Squad, SquadData)
    case updateAllDials(Bool)
    case flipDial
}

struct AppEnvironment {
    let squadsService = SquadsService(moc: NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType))
}

func reducer(state: inout AppState, action: AppAction, environment: AppEnvironment) -> AnyPublisher<AppAction, Error>
{
    switch(action) {
        case .loadSquadsList:
            return environment
                .squadsService
                .loadSquadsListFromCoreData()
                .eraseToAnyPublisher()
        
        case .updateSquadsList(let squads):
            state.squadState.squadDataList.removeAll()
            squads.forEach{ squad in
                state.squadState.squadDataList.append(squad)
            }
            
            state.squadState.numSquads = squads.count
            state.squadState.squadNames = squads.compactMap{ $0.name }
        
        default:
            return Empty().eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}


/*
 This logic should live in Store.send(action: ActionProtocol) { action.execute(&state,environment).sink....
}
 The caller of Store.send() creates the action object...
 Then the reduce function is no longer needed...
*/
func reducer_new(state: inout AppState, action: AppAction, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
{
    switch(action) {
        case .loadSquadsList:
            return LoadSquadsList()
                .execute(state: &state, environment: environment)
        
        case .updateSquadsList(let squads):
            return UpdateSquadsListAction(squads: squads).execute(state: &state, environment: environment)
        
        default:
            return Empty().eraseToAnyPublisher()
    }
}


struct SquadsService {
    let moc: NSManagedObjectContext
    
    func loadSquadsListFromCoreData() -> AnyPublisher<AppAction, Error> {
        let ret = Future<AppAction, Error> { promise in
            do {
                let fetchRequest = SquadData.fetchRequest()
                let fetchedObjects = try self.moc.fetch(fetchRequest) as! [SquadData]
                let action = AppAction.updateSquadsList(fetchedObjects)
                return promise(.success(action))
            } catch {
                print(error)
                return promise(.failure(error))
            }
        }
        
        return ret
            .eraseToAnyPublisher()
    }
    
    func loadSquadsListFromCoreData() -> AnyPublisher<ActionProtocol, Error> {
        let ret = Future<ActionProtocol, Error> { promise in
            do {
                let fetchRequest = SquadData.fetchRequest()
                let fetchedObjects = try self.moc.fetch(fetchRequest) as! [SquadData]
                let action = UpdateSquadsListAction(squads: fetchedObjects)
                return promise(.success(action))
            } catch {
                print(error)
                return promise(.failure(error))
            }
        }
        
        return ret
            .eraseToAnyPublisher()
    }
}
