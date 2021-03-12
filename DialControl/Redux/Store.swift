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
    var squadDataList: [SquadData] = []
    var displayDeleteAllSquadsConfirmation: Bool = false
    var faction: String = ""
    var numSquads: Int {
        return squadDataList.count
    }
    
    var shipPilots: [ShipPilot] = []
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
    case updateSquad(SquadData)
    case favorite(Bool, SquadData)
    case refreshSquads
    case updateFavorites(Bool)
    case getShips(Squad, SquadData)
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
    func filterByFavorites(_ isFavorite: Bool = true) {
        let showFavoritesOnly = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
        
        state.squadDataList = state.squadDataList.filter{ $0.favorite == showFavoritesOnly }
    }
 
    func filterByFaction(faction: Faction) {
//            state.squadDataList = state.squadDataList.filter{ $0.faction == faction }
    }
    
    switch(action) {
        case let .getShips(squad, data):
            state.shipPilots = SquadCardViewModel.getShips(
                squad: squad,
                squadData: data)
        
        case .updateFavorites(let showFavorites):
            UserDefaults.standard.set(showFavorites, forKey: "displayFavoritesOnly")
        
        case .refreshSquads:
            filterByFavorites()
        
        case .loadSquads:
            return environment.service
                .loadSquadsListRx()
                .replaceError(with: [])
                .map { .faction(action: .setSquads(squads: $0)) }
                .eraseToAnyPublisher()
        
        case let .setSquads(squads):
            let showFavoritesOnly = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
            
            if showFavoritesOnly {
                filterByFavorites()
            } else {
                state.squadDataList = squads
            }
        
        case .deleteAllSquads:
            state.squadDataList.forEach {
                environment.service.deleteSquad(squadData: $0)
            }
        
        case let .deleteSquad(squad):
            environment.service.deleteSquad(squadData: squad)
        
        case let .updateSquad(squad):
            environment.service.updateSquad(squadData: squad)
        
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
