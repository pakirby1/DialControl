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
    var squad: MySquadViewState
    var ship: MyShipViewState
}

struct MyShipViewState {
    /*
     Redux_SquadView:
     var shipPilots: [ShipPilot] {
         self.store.state.squad.shipPilots
     }
     */
    var pilotState: PilotState?
    var pilotStateData: PilotStateData?
    var shipImageURL: String = ""
}

struct MySquadViewState {
    var shipPilots: [ShipPilot] = []
    var squad: Squad?
    var squadData: SquadData?
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
    case squad(action: MySquadAction)
    case ship(action: MyShipAction)
}

enum MyShipAction {
    case initState(PilotStateData, PilotState)
    case loadShipImage(String, String, Squad)
    case updateHull(Int, Int)
    case updateShield(Int, Int)
    case updateForce(Int, Int)
    case updateCharge(Int, Int)
    case updateUpgradeCharge(UpgradeStateData, Int, Int)
    case updateUpgradeSelectedSide(UpgradeStateData, Bool)
    case updateShipIDMarker(String)
    case reset
    case updateSelectedManeuver(String)
    case updateDialStatus(DialStatus)
}

enum MySquadAction {
    case updateSquad(SquadData)
    case updatePilotState(PilotStateData, PilotState)
    case getShips(Squad, SquadData)
    case flipDial(PilotStateData, PilotState)
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

struct MyEnvironment {
    var squadService: SquadService
    var pilotStateService: PilotStateService
    var jsonService: JSONService
}

// MARK: - Redux Store
func myAppReducer(
    state: inout MyAppState,
    action: MyAppAction,
    environment: MyEnvironment
) -> AnyPublisher<MyAppAction, Never>
{
    switch action {
        case .faction(let action):
            return factionReducer(state: &state.faction,
                           action: action,
                           environment: environment)
        
        case .squad(let action):
            return squadReducer(state: &state.squad,
                                  action: action,
                                  environment: environment)
        
        case .ship(let action):
            return shipReducer(state: &state.ship,
                              action: action,
                              environment: environment)
        
    }
    
//    return Empty().eraseToAnyPublisher()
}

func shipReducer(state: inout MyShipViewState,
                    action: MyShipAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    func reset() {
        state.pilotStateData?.change(update: {
            $0.reset()
            updateState(newData: $0)
        })
    }
    
    func updateState(newData: PilotStateData) {
        print("\(Date()) PAK_updateState: \(newData.description)")
        
        let json = PilotStateData.serialize(type: newData)
        /// where do we get a PilotState instance????
        guard let pilotState = state.pilotState else { return }

        environment.pilotStateService.updatePilotState(pilotState: pilotState,
                                                state: json,
                                                pilotIndex: newData.pilot_index)

        state.pilotStateData = newData
    }
    
    func updateHull(_ active: Int, _ inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
        
//        let x = { (psd: PilotStateData) in psd.updateHull(active: active, inactive: inactive) }
        
        update(handler: { $0.updateHull(active: active, inactive: inactive) })
    }
    
    func update(handler: (inout PilotStateData) -> ()) {
        state.pilotStateData?.change(update: {
            print("PAK_\(#function) pilotStateData.id: \($0)")
            handler(&$0)
            updateState(newData: $0)
        })
    }
    
    switch(action) {
        // FIXME: Do we really need this?  or can we load this from CoreData?
        case let .initState(pilotStateData, pilotState):
            state.pilotStateData = pilotStateData
            state.pilotState = pilotState
        
        case let .loadShipImage(shipName, pilotName, squad):
            state.shipImageURL = environment
                .jsonService
                .loadShipFromJSON(shipName: shipName,
                                  pilotName: pilotName,
                                  squad: squad).1.image
        
        case let .updateHull(active, inactive):
            updateHull(active, inactive)
        
        case let .updateShield(active, inactive):
            print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            
            state.pilotStateData?.change(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateShield(active: active, inactive: inactive)
                updateState(newData: $0)
            })
        
        case let .updateForce(active, inactive):
            print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            
            state.pilotStateData?.change(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateForce(active: active, inactive: inactive)
                updateState(newData: $0)
            })
        
        case let .updateCharge(active, inactive):
            print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            
            state.pilotStateData?.change(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateForce(active: active, inactive: inactive)
                updateState(newData: $0)
            })
        
        case let .updateShipIDMarker(marker):
            print("\(Date()) \(#function) : \(marker)")
            state.pilotStateData?.change(update: {
                $0.updateShipID(shipID: marker)
                updateState(newData: $0)
            })
        
        case let .updateSelectedManeuver(maneuver):
            print("\(Date()) \(#function) : \(maneuver)")
            state.pilotStateData?.change(update: {
                $0.updateManeuver(maneuver: maneuver)
                updateState(newData: $0)
            })
        
        case let .updateUpgradeCharge(upgrade, active, inactive):
            print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            upgrade.change(update: { newUpgrade in
                print("PAK_\(#function) pilotStateData.id: \(newUpgrade)")
                newUpgrade.updateCharge(active: active, inactive: inactive)
                
                // the old upgrade state is in the pilotStateData, so we need
                // to replace the old upgrade state with the new upgrade state
                // in $0
                if let upgrades = state.pilotStateData?.upgradeStates {
                    if let indexOfUpgrade = upgrades.firstIndex(where: { $0.xws == newUpgrade.xws }) {
                        state.pilotStateData?.upgradeStates?[indexOfUpgrade] = newUpgrade
                    }
                }
                
                updateState(newData: state.pilotStateData!)
            })
        
        case let .updateUpgradeSelectedSide(upgrade, selectedSide):
            print("\(Date()) PAK_\(#function) : side: \(selectedSide)")
            upgrade.change(update: { newUpgrade in
                print("PAK_\(#function) pilotStateData.id: \(newUpgrade)")
                newUpgrade.updateSelectedSide(side: selectedSide ? 1 : 0)
                
                // the old upgrade state is in the pilotStateData, so we need
                // to replace the old upgrade state with the new upgrade state
                // in $0
                if let upgrades = state.pilotStateData?.upgradeStates {
                    if let indexOfUpgrade = upgrades.firstIndex(where: { $0.xws == newUpgrade.xws }) {
                        state.pilotStateData?.upgradeStates?[indexOfUpgrade] = newUpgrade
                    }
                }
                
                updateState(newData: state.pilotStateData!)
            })
        
        case .reset :
            reset()
        
        case .updateDialStatus(let status):
            print("\(Date()) \(#function) : \(status)")
            state.pilotStateData?.change(update: {
                $0.updateDialStatus(status: status)
                updateState(newData: $0)
            })
    }
    
    return Empty().eraseToAnyPublisher()
}

func squadReducer(state: inout MySquadViewState,
                    action: MySquadAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case let .flipDial(pilotStateData, pilotState):
            pilotStateData.change(update: {
                var newPSD = $0
                
                newPSD.dial_status.handleEvent(event: .dialTapped)
                
                environment
                    .pilotStateService
                    .updateState(newData: newPSD, state: pilotState)
                
                print("\(Date()) PAK_\(#function) after pilotStateData id: \(String(describing: pilotState.id)) dial_status: \(newPSD.dial_status)")
            })
                            
        case let .updateSquad(squad):
            environment
                .squadService
                .updateSquad(squadData: squad)
        
        case let .updatePilotState(pilotStateData, pilotState):
            environment
                .pilotStateService
                .updateState(newData: pilotStateData, state: pilotState)
        
        case let .getShips(squad, data):
            state.squad = squad
            state.squadData = data
            state.shipPilots = SquadCardViewModel.getShips(
                squad: squad,
                squadData: data)
    }
    
    return Empty().eraseToAnyPublisher()
}

func factionReducer(state: inout FactionSquadListState,
                    action: MyFactionSquadListAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    func filterByFavorites(_ isFavorite: Bool = true) {
        let showFavoritesOnly = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
        
        state.squadDataList = state.squadDataList.filter{ $0.favorite == showFavoritesOnly }
    }
 
    func filterByFaction(faction: Faction) {
//            state.squadDataList = state.squadDataList.filter{ $0.faction == faction }
    }
    
    func loadAllSquads() -> AnyPublisher<MyAppAction, Never> {
        return Just<MyAppAction>(.faction(action: .loadSquads)).eraseToAnyPublisher()
    }
    
    switch(action) {
        case let .getShips(squad, data):
            state.shipPilots = SquadCardViewModel.getShips(
                squad: squad,
                squadData: data)
        
        case .updateFavorites(let showFavorites):
            UserDefaults.standard.set(showFavorites, forKey: "displayFavoritesOnly")
            return loadAllSquads()
        
        case .refreshSquads:
            filterByFavorites()
        
        case .loadSquads:
            return environment
                .squadService
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
                environment
                    .squadService
                    .deleteSquad(squadData: $0)
            }
            
            return loadAllSquads()
        
        case let .deleteSquad(squad):
            environment
                .squadService
                .deleteSquad(squadData: squad)
        
            return loadAllSquads()
        
        case let .updateSquad(squad):
            environment
                .squadService
                .updateSquad(squadData: squad)
            
            return loadAllSquads()
        
        case let .favorite(isFavorite, squad):
            let x = squad
            x.favorite = isFavorite
            environment
                .squadService
                .updateSquad(squadData: x)
            
            return loadAllSquads()
    }
    
    return Empty().eraseToAnyPublisher()
}

typealias MyAppStore = Store<MyAppState, MyAppAction, MyEnvironment>
typealias Reducer<State, Action, Environment> =
(inout State, Action, Environment) -> AnyPublisher<Action, Never>

class Store<State, Action, Environment> : ObservableObject {
    @Published var state: State
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
