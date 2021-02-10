//
//  SquadXWSImportAction.swift
//  DialControl
//
//  Created by Phil Kirby on 2/9/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine

func noAction() -> AnyPublisher<ActionProtocol, Never> {
    return Empty().eraseToAnyPublisher()
}

struct AlertDismissedAction: ActionProtocol {
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
    {
        state.xwsImportSquadState.showAlert = false
        state.xwsImportSquadState.alertText = ""
        
        return noAction()
    }
}

struct SerializationErrorAction : ActionProtocol {
    let message: String
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
    {
        state.xwsImportSquadState.showAlert = true
        state.xwsImportSquadState.alertText = message
        
        return noAction()
    }
}

struct ImportSquadAction : ActionProtocol {
    let json: String
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never>
    {
        return loadSquad(jsonString: json)
            .subscribe(on: DispatchQueue.main)
            .map{ squad -> ActionProtocol in
                return SaveSquadAction(json: self.json, squad: squad)
            }
            .catch{ (error: XWSImportError) -> Just<ActionProtocol> in
                switch(error) {
                    case .serializationError(let message) :
                        return Just(SerializationErrorAction(message: message))
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func loadSquad(jsonString: String) -> AnyPublisher<Squad, XWSImportError>
    {
        return Future<Squad, XWSImportError>{ promise in
            // replace janky yasb exported to remove '-' characters.
            let jsonStringNew = jsonString
                .replacingOccurrences(of: "force-power", with: "forcepower")
                .replacingOccurrences(of: "tactical-relay", with: "tacticalrelay")
            
            let squad = Squad.serializeJSON(jsonString: jsonStringNew) { errorString in
                return promise(.failure(XWSImportError.serializationError(errorString)))
            }
            
            return promise(.success(squad))
        }.eraseToAnyPublisher()
    }
}

enum XWSImportError: Error {
    case serializationError(String)
}

struct SaveSquadAction: ActionProtocol {
    let json: String
    let squad: Squad
    
    var squadName: String {
        return squad.name ?? ""
    }
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never> {
        return environment
            .squadsService
            .saveSquad(jsonString: self.json, name: self.squadName)
            .map{ squadData -> ActionProtocol in
                let action = CreatePilotStateAction(json: self.json,
                                                    squadName: self.squadName,
                                                    squad: self.squad,
                                                    squadData: squadData)
                
                return action
            }
            .catch{ (error: Error) -> Just<ActionProtocol> in
                return Just(SerializationErrorAction(message: "Unable to save squad"))
            }
            .eraseToAnyPublisher()
    }
}

struct CreatePilotStateAction: ActionProtocol {
    let json: String
    let squadName: String
    let squad: Squad
    let squadData: SquadData
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Never> {
        
        environment
            .pilotStateService
            .createPilotState(squad: squad, squadData: squadData)
        
        state.xwsImportSquadState.showAlert = true
        state.xwsImportSquadState.alertText = "XWS Imported"
        
        return noAction()
    }
}
