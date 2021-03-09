//
//  Store.swift
//  DialControl
//
//  Created by Phil Kirby on 3/5/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import CoreData

// MARK:- MyAppState
struct MyAppState {
    var faction: FactionSquadListState
}

struct FactionSquadListState {
    var squadList: [SquadData] = []
    var displayDeleteAllSquadsConfirmation: Bool = false
}

// MARK:- MyAppAction
enum MyAppAction {
    case faction(action: MyFactionSquadListAction)
}

enum MyFactionSquadListAction {
    case loadSquads
    case setSquads(squads: [SquadData])
    case deleteAllSquads
    case deleteSquad(SquadData)
    case favorite(Bool, SquadData)
}

struct World {
    var service: SquadService
}

// MARK: - Redux Store
func myAppReducer(
    state: inout MyAppState,
    action: MyAppAction,
    environment: World
) -> AnyPublisher<MyAppAction, Never>
{
    switch action {
        case .faction(let action):
            return factionReducer(state: &state.faction,
                           action: action,
                           environment: environment)
    }
    
//    return Empty().eraseToAnyPublisher()
}

func factionReducer(state: inout FactionSquadListState,
                    action: MyFactionSquadListAction,
                    environment: World) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case .loadSquads:
            return environment.service
                .loadSquadsListRx()
                .replaceError(with: [])
                .map { .faction(action: .setSquads(squads: $0)) }
                .eraseToAnyPublisher()
        
        case let .setSquads(squads):
            state.squadList = squads
        
        case .deleteAllSquads:
            state.squadList.forEach {
                environment.service.deleteSquad(squadData: $0)
        }
        
        case let .deleteSquad(squad):
            environment.service.deleteSquad(squadData: squad)
        
        case let .favorite(isFavorite, squad):
            let x = squad
            x.favorite = isFavorite
            environment.service.updateSquad(squadData: x)
    }
    
    return Empty().eraseToAnyPublisher()
}

typealias MyAppStore = Store<MyAppState, MyAppAction, World>
typealias Reducer<State, Action, Environment> =
(inout State, Action, Environment) -> AnyPublisher<Action, Never>

class Store<State, Action, Environment> : ObservableObject {
    @Published private(set) var state: State
    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    private var cancellables = Set<AnyCancellable>()
    
    init(state: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment)
    {
        self.state = state
        self.reducer = reducer
        self.environment = environment
    }
}

extension Store {
//    func send(action: ActionProtocol) {
//        action.execute(state: &state as! AppState, environment: environment).sink(
//            receiveCompletion: { completion in
//                switch(completion) {
//                    case .finished:
//                        print("finished")
//                    case .failure:
//                        print("failure")
//                }
//            },
//            receiveValue: { nextAction in
//                self.send(action: nextAction)
//            }).store(in: &cancellables)
//    }
}

extension Store {
    func send(_ action: Action) {
        let nextAction = reducer(&state, action, environment)

        nextAction
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}
