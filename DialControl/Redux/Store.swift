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
    let squadList: [SquadData] = []
}

// MARK:- MyAppAction
enum MyAppAction {
    case test
}

// MARK: - Redux Store
func myAppReducer(
    state: inout MyAppState,
    action: MyAppAction,
    environment: World
) -> AnyPublisher<MyAppAction, Never>
{
//    switch action {
//    case let .setSearchResults(repos):
//        state.searchResult = repos
//    case let .search(query):
//        return environment.service
//            .searchPublisher(matching: query)
//            .replaceError(with: [])
//            .map { AppAction.setSearchResults(repos: $0) }
//            .eraseToAnyPublisher()
//    }
    return Empty().eraseToAnyPublisher()
}

struct World {
    var service: SquadService
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
