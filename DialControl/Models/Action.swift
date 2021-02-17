//
//  Action.swift
//  DialControl
//
//  Created by Phil Kirby on 1/17/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine

/// AppState & AppEnvironment should be generic
protocol ActionProtocol {
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
}

struct LoadSquadsList : ActionProtocol {
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
    {
        return environment
            .squadsService
            .loadSquadsListFromCoreData()
            .eraseToAnyPublisher()
    }
}

struct UpdateSquadsListAction: ActionProtocol {
    let squads: [SquadData]
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
    {
        state.squadState.squadDataList.removeAll()
        squads.forEach{ squad in
            state.squadState.squadDataList.append(squad)
        }
        
        state.squadState.numSquads = squads.count
        state.squadState.squadNames = squads.compactMap{ $0.name }
        
        return Empty().eraseToAnyPublisher()
    }
}

struct ChargeAction : ActionProtocol {
    let pilotIndex: Int

    enum ChargeActionType {
        case spend(StatButtonType)
        case recover(StatButtonType)
        case reset
    }

    let type: ChargeActionType

    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
    {
//        func updateState(newData: PilotStateData) {
//            print("\(Date()) PAK_updateState: \(newData.description)")
//
//            let json = PilotStateData.serialize(type: newData)
//            /// where do we get a PilotState instance????
//            guard let state = self.pilotState else { return }
//
//            self.pilotStateService.updatePilotState(pilotState: state,
//                                                    state: json,
//                                                    pilotIndex: newData.pilot_index)
//
//            self.pilotStateData = newData
//        }
        
        func spend(pilotStateData: PilotStateData,
                   statButtonType: StatButtonType)
        {
            switch(statButtonType) {
            case .hull:
                pilotStateData.hull.decrement()
            case .shield:
                pilotStateData.shield.decrement()
            case .force:
                pilotStateData.force.decrement()
            case .charge:
                pilotStateData.charge.decrement()
            }
        }

        func recover(pilotStateData: PilotStateData,
                   statButtonType: StatButtonType)
        {
            var newPilotStateData: PilotStateData

            switch(statButtonType) {
                case .hull:
                    newPilotStateData = pilotStateData.hull.increment()
                case .shield:
                    newPilotStateData = pilotStateData.shield.increment()
                case .force:
                    newPilotStateData = pilotStateData.force.increment()
                case .charge:
                    newPilotStateData = pilotStateData.charge.increment()
            }

            // call updateState(newPilotStateData)
            environment.squadsService
        }

        let shipPilot = state.squadState.shipPilots[pilotIndex]

        if let pilotStateData = shipPilot.pilotStateData {
            switch(type) {
                case .spend(let statButtonType) :
                    spend(pilotStateData: pilotStateData, statButtonType: statButtonType)
                case .recover(let statButtonType) :
                    recover(pilotStateData: pilotStateData, statButtonType: statButtonType)
                case .reset:
                    print("Reset not implemented")
                }
        }
        
        return Empty().eraseToAnyPublisher()
    }
}

protocol ViewPropertyGenerating: class {
    associatedtype Properties
    var viewProperties: Properties { get set }
    var store: Store<AppState, AppAction> { get }
    
    func buildViewProperties(state: AppState) -> Properties
}

extension ViewPropertyGenerating {
    func configureViewProperties() -> AnyCancellable {
        return store.$state.sink { state in
            self.viewProperties = self.buildViewProperties(state: state)
        }
    }
}

//MARK: - Environment
struct AppEnvironment_New {
    let squadService: SquadService
}

//MARK: - Actions
enum AppAction_New {
    case importSquad(SquadXWSImportAction)
    case squadList(FactionSquadListAction)
    case squad(SquadAction)
    case ship(ShipAction)
}

enum SquadXWSImportAction {
    case importXWS(String)
    case displayAlert(String)
    case alertDismissed
    case saveSquad(String, Squad)
    case createPilotState(Squad, SquadData)
}

enum FactionSquadListAction {
    case displayFilterView
    case showFavorites
    case deleteAllSquads
    case displayImportView
    case favoriteSquad(UUID)
    case deleteSquad(UUID)
}

enum SquadAction {
    case engage
    case reveal
    case dialTap
    case displayShipView(UUID)
    case resetAllShips
}

enum ShipAction {
    case reset
    case setDial(String)
    case upgradeTap
    case displaySquadView
    case updateHull(Int, Int)
    case updateShield(Int, Int)
    case updateForce(Int, Int)
}

//MARK: - Reducers
typealias Reducer<State, Action, Environment> = (inout State, Action, Environment) -> AnyPublisher<Action, Never>

func appReducer(state: inout AppState,
                action: AppAction_New,
                environment: AppEnvironment_New) -> AnyPublisher<AppAction_New, Never>
{
    switch(action) {
        case .importSquad(let importAction) :
            return importSquadReducer(state: &state, action: importAction, environment: environment)
        case .squadList(_):
            return Empty().eraseToAnyPublisher()
        case .squad(_):
            return Empty().eraseToAnyPublisher()
        case .ship(_):
            return Empty().eraseToAnyPublisher()
    }
    return Empty().eraseToAnyPublisher()
}

enum SquadXWSImportError : Error {
    case serializationError(String)
}

func importSquadReducer(state: inout AppState,
                        action: SquadXWSImportAction,
                        environment: AppEnvironment_New) -> AnyPublisher<AppAction_New, Never>
{
    func loadSquad(jsonString: String) -> AnyPublisher<Squad, Error> {
        let newJSON = jsonString
            .replacingOccurrences(of: "force-power", with: "forcepower")
            .replacingOccurrences(of: "tactical-relay", with: "tacticalrelay")
        
        return Future<Squad, Error> { promise in
            let squad = Squad.serializeJSON(jsonString: newJSON) { errorString in
                return promise(.failure(SquadXWSImportError.serializationError(errorString)))
            }
            
            return promise(.success(squad))
        }.eraseToAnyPublisher()
    }
    
    /*
     func saveSquad(jsonString: String, name: String) -> SquadData {
         return self.squadService.saveSquad(jsonString: jsonString, name: name)
     }
     */
    func saveSquad(jsonString: String, name: String) -> AnyPublisher<SquadData, Error> {
        return Future<SquadData, Error> { promise in
            let squadData = environment
                .squadService
                .saveSquad(jsonString: jsonString, name: name)
        
            return promise(.success(squadData))
        }.eraseToAnyPublisher()
    }
    
    switch(action) {
        case .importXWS(let xws):
            // Create a Squad from xws
            let xwsLocal = xws
            
            return loadSquad(jsonString: xwsLocal)
                .map{ squad in
                    AppAction_New.importSquad(SquadXWSImportAction.saveSquad(xwsLocal, squad))
                }
                .replaceError(with: AppAction_New.importSquad(SquadXWSImportAction.alertDismissed))
                .eraseToAnyPublisher()
        
        case .alertDismissed:
            return Empty().eraseToAnyPublisher()
        case .displayAlert(let messsage):
            return Empty().eraseToAnyPublisher()
        case let .saveSquad(json, squad):
            // Save Squad to CoreData
            return saveSquad(jsonString: json, name: squad.name ?? "")
                .map{ squadData in
                    AppAction_New.importSquad(.createPilotState(squad, squadData))
                }
                .replaceError(with: .importSquad(.alertDismissed))
                .eraseToAnyPublisher()
            
        case let .createPilotState(squad, squadData):
            // Create a PilotStateData in CoreData
            return Empty().eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}
