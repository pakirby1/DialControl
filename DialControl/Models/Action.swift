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
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
}

struct LoadSquadsList : ActionProtocol {
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
    {
//        return environment
//            .squadsService
//            .loadSquadsListFromCoreData()
//            .eraseToAnyPublisher()
        
        return Empty().eraseToAnyPublisher()
    }
}

struct UpdateSquadsListAction: ActionProtocol {
    let squads: [SquadData]
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
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

    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
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
    var store: Store { get }
    
    func buildViewProperties(state: AppState) -> Properties
}

extension ViewPropertyGenerating {
    func configureViewProperties() -> AnyCancellable {
        return store.$state.sink { state in
            self.viewProperties = self.buildViewProperties(state: state)
        }
    }
}
