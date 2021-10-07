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
    var xwsImport: MyXWSImportViewState
    var factionFilter: FactionFilterState
    var tools: ToolsViewState
}

struct ToolsViewState {
    var imageUrl: String = ""
    var downloadImageEvent: DownloadImageEvent?
    var currentImage: DownloadEventEnum = .idle
    var message: String = ""
    var downloadImageEventState: DownloadImageEventState = .idle
}

struct FactionFilterState {
    var factions: [Faction] = []
    var selectedFaction: Faction = .none
}

struct MyXWSImportViewState {
    var showAlert: Bool = false
    var alertText: String = ""
    var navigateBack: Bool = false
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
//    var shipPilotsCollection: Array<[ShipPilot]> = []
}

// MARK:- MyAppAction
enum MyAppAction {
    case faction(action: MyFactionSquadListAction)
    case squad(action: MySquadAction)
    case ship(action: MyShipAction)
    case xwsImport(action: MyXWSImportAction)
    case factionFilter(action: MyFactionFilterListAction)
    case tools(action: ToolsAction)
}

enum ToolsAction {
    case deleteImageCache
    case downloadAllImages
    case setDownloadEvent(DownloadEventEnum)
    case cancelDownloadAllImages
    case setCancelDownloadAllImages(DownloadAllImagesError)
}

enum DownloadAllImagesError: Error, CustomStringConvertible {
    case cancelled
    case serverError(Error)
    
    var description: String {
        switch(self) {
            case .cancelled:
                return "Cancelled"
            case .serverError(let error):
                return error.localizedDescription
        }
    }
}

enum MyXWSImportAction {
    case importXWS(String)
    case importSuccess
    case displayAlert(String)
}

enum MyFactionFilterListAction {
    case loadFactions
    case selectFaction(Faction)
    case deselectFaction(Faction)
    case deselectAll
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
    case updateFavorites(Bool)
    case getShips(Squad, SquadData)
}

struct MyEnvironment {
    var squadService: SquadService
    var pilotStateService: PilotStateService
    var jsonService: JSONService
    var imageService: ImageService
}

// MARK: - Redux Store
func myAppReducer(
    state: inout MyAppState,
    action: MyAppAction,
    environment: MyEnvironment
) -> AnyPublisher<MyAppAction, Never>
{
    switch action {
        case .tools(let action):
            return toolsReducer(state: &state.tools,
                                action: action,
                                environment: environment)
            
        case .faction(let action):
            return factionReducer(state: &state,
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
        
        case .xwsImport(let action):
            return xwsImportReducer(state: &state.xwsImport,
                               action: action,
                               environment: environment)
        
        case .factionFilter(let action):
            return factionFilterReducer(state: &state.factionFilter,
                                        action: action,
                                        environment: environment)
    }
    
//    return Empty().eraseToAnyPublisher()
}

func toolReducerFactory(isMock: Bool = false) -> (inout ToolsViewState, ToolsAction, MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
        return toolsReducer
}

func buildSetDownloadEvent(result: Result<DownloadEventEnum, Error>) -> MyAppAction {
    switch(result) {
        case .success(let event):
            return MyAppAction.tools(action:ToolsAction.setDownloadEvent(event))
        case .failure(let error):
            let failureEvent = DownloadEventEnum.failed(error)
            return MyAppAction.tools(action:ToolsAction.setDownloadEvent(failureEvent))
    }
}

func toolsReducer(state: inout ToolsViewState,
                 action: ToolsAction,
                 environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case .deleteImageCache:
            return Empty().eraseToAnyPublisher()
        
        case .downloadAllImages:
            state.message = ""
            return environment
                .imageService
                .downloadAllImages()
                .map(buildSetDownloadEvent(result:))
                .eraseToAnyPublisher()
 
        case .cancelDownloadAllImages:
            return Empty().eraseToAnyPublisher()
            
        case .setCancelDownloadAllImages(let event):
            state.message = event.description
            return Empty().eraseToAnyPublisher()
            
        case .setDownloadEvent(let event):
            state.currentImage = event
            return Empty().eraseToAnyPublisher()
            
        default:
            return Empty().eraseToAnyPublisher()
    }
}

func factionFilterReducer(state: inout FactionFilterState,
                          action: MyFactionFilterListAction,
                          environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case .loadFactions:
            return Empty().eraseToAnyPublisher()
            
        case .selectFaction(let faction):
            if faction == .none {
                state.selectedFaction = .none
            } else {
                // If faction is already selected, remove it
                if state.selectedFaction == faction {
                    state.selectedFaction = .none
                } else {
                    state.selectedFaction = faction
                }
            }

            return Empty().eraseToAnyPublisher()
            
        case .deselectFaction(let faction):
            return Empty().eraseToAnyPublisher()
        case .deselectAll:
            return Empty().eraseToAnyPublisher()
    }
    
    return Empty().eraseToAnyPublisher()
}

func xwsImportReducer(state: inout MyXWSImportViewState,
                      action: MyXWSImportAction,
                      environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never> {
    func importXWS(xws: inout String) -> AnyPublisher<MyAppAction, Never> {
        do {
            let squad = try environment.squadService.loadSquad_throws(jsonString: &xws)
        
            if squad.name != Squad.emptySquad.name {
                // Save the squad JSON to CoreData
                let squadData = try environment.squadService.saveSquad_throws(jsonString: xws,
                                                         name: squad.name ?? "")
                
                try environment.pilotStateService.createPilotState_throws(squad: squad, squadData: squadData)
                
                //                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
                return Just<MyAppAction>(.xwsImport(action: .importSuccess))
                    .eraseToAnyPublisher()
            }
        } catch {
            print(error.localizedDescription)
            return Just<MyAppAction>(.xwsImport(action: .displayAlert(error.localizedDescription)))
                .eraseToAnyPublisher()
        }
        
        return Empty()
            .eraseToAnyPublisher()
    }
    
    switch(action) {
        case .importXWS(var xws):
            return importXWS(xws: &xws)
                
        case .importSuccess:
            state.showAlert = true
            state.alertText = "XWS Imported"
        
        case .displayAlert(let message):
            state.showAlert = true
            state.alertText = message
    }
    
    return Empty().eraseToAnyPublisher()
}

func shipReducer(state: inout MyShipViewState,
                    action: MyShipAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    func reset() {
        print("\(Date()) \(#function) : reset")
        update(psdHandler: { $0.reset() })
    }
    
    func updateShipIDMarker(marker: String) {
        print("\(Date()) \(#function) : \(marker)")
        update(psdHandler: { $0.updateShipID(shipID: marker) })
    }
    
    func updateSelectedManeuver(maneuver: String ) {
        print("\(Date()) \(#function) : \(maneuver)")
        update(psdHandler: { $0.updateManeuver(maneuver: maneuver) })
    }
    
    func updateHull(_ active: Int, _ inactive: Int) {
        print(active, inactive)
        update(psdHandler: { $0.updateHull(active: active, inactive: inactive) })
    }
    
    func updateShield(_ active: Int , _ inactive: Int ) {
        print(active, inactive)
        update(psdHandler: { $0.updateShield(active: active, inactive: inactive) })
    }
    
    func updateForce(_ active: Int, _ inactive: Int) {
        print(active, inactive)
        update(psdHandler: { $0.updateForce(active: active, inactive: inactive) })
    }
    
    func updateCharge(_ active: Int , _ inactive: Int ) {
        print(active, inactive)
        update(psdHandler: { $0.updateCharge(active: active, inactive: inactive) })
    }
    
    func updateUpgradeCharge(upgrade: UpgradeStateData, active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
        update(upgrade: upgrade,
               upgradeHandler: { $0.updateCharge(active: active, inactive: inactive) })
    }
    
    func updateUpgradeSelectedSide(upgrade: UpgradeStateData, selectedSide: Bool) {
        print("\(Date()) PAK_\(#function) : side: \(selectedSide)")
        update(upgrade: upgrade,
               upgradeHandler: { $0.updateSelectedSide(side: selectedSide ? 1 : 0) })
    }
    
    func updateDialStatus(status: DialStatus) {
        print("\(Date()) \(#function) : \(status)")
        update(psdHandler: { $0.updateDialStatus(status: status) })
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
    
    func update(psdHandler: (inout PilotStateData) -> ()) {
        state.pilotStateData?.change(update: {
            print("PAK_\(#function) pilotStateData.id: \($0)")
            psdHandler(&$0)
            updateState(newData: $0)
        })
    }

    func update(upgrade: UpgradeStateData, upgradeHandler: (inout UpgradeStateData) -> ()) {
        upgrade.change(update: { newUpgrade in
            print("PAK_\(#function) pilotStateData.id: \(newUpgrade)")
            upgradeHandler(&newUpgrade)
            
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
    }
    
    func printStat(_ active: Int, _ inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
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
            updateShield(active, inactive)
        
        case let .updateForce(active, inactive):
            updateForce(active, inactive)
        
        case let .updateCharge(active, inactive):
            updateCharge(active, inactive)
        
        case let .updateShipIDMarker(marker):
            updateShipIDMarker(marker: marker)
        
        case let .updateSelectedManeuver(maneuver):
            updateSelectedManeuver(maneuver: maneuver)
        
        case let .updateUpgradeCharge(upgrade, active, inactive):
            updateUpgradeCharge(upgrade: upgrade, active: active, inactive: inactive)
        
        case let .updateUpgradeSelectedSide(upgrade, selectedSide):
            updateUpgradeSelectedSide(upgrade: upgrade, selectedSide: selectedSide)
        
        case .reset :
            reset()
        
        case .updateDialStatus(let status):
            updateDialStatus(status: status)
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

func factionReducer(state: inout MyAppState,
                    action: MyFactionSquadListAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    var showFavoritesOnly: Bool {
        get { UserDefaults.standard.bool(forKey: "displayFavoritesOnly") }
        set { UserDefaults.standard.set(newValue, forKey: "displayFavoritesOnly") }
    }
    
    func loadAllSquads() -> AnyPublisher<MyAppAction, Never> {
        return Just<MyAppAction>(.faction(action: .loadSquads)).eraseToAnyPublisher()
    }
    
    func setSquads(squads: [SquadData]) {
        func filterByFavorites(_ isFavorite: Bool = true) {
            state.faction.squadDataList = state.faction.squadDataList.filter{ $0.favorite == showFavoritesOnly }
        }
        
        func filterByFactions() {
            var filters: [SquadDataFilter] = []
            
            let selectedFaction = state.factionFilter.selectedFaction
            
            if (selectedFaction != .none) {
                let filter: (SquadData) -> Bool = { $0.hasFaction(faction: selectedFaction) }
                filters.append(filter)
            }
            
            state.faction.squadDataList = filters.reduce(state.faction.squadDataList) { squads, filter in
                return squads.filter(filter)
            }
        }

        func setSquads_Old(squads: [SquadData]) {
            let showFavoritesOnly = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
            
            if showFavoritesOnly {
                filterByFavorites()
            } else {
                state.faction.squadDataList = squads
            }
        }
        
        func setSquads_New(squads: [SquadData]) {
            var filters: [SquadDataFilter] = []
            
            if showFavoritesOnly {
                filters.append({ $0.favorite == showFavoritesOnly })
            }
            
            let selectedFaction = state.factionFilter.selectedFaction
            
            if (selectedFaction != .none) {
                let filter: (SquadData) -> Bool = { $0.hasFaction(faction: selectedFaction) }
                filters.append(filter)
            }
            
            state.faction.squadDataList = filters.reduce(squads) { squads, filter in
                return squads.filter(filter)
            }
        }
        
//        setSquads_Old(squads: squads)
        measure(name: "favoriteTapped.setSquads") {
            setSquads_New(squads: squads)
        }
    }
    
    print("favoriteTapped: \(action)")
    
    switch(action) {
        case let .getShips(squad, data):
            logMessage("PAK_damagedPoints .getShips() \(data)")
            let x = SquadCardViewModel.getShips(
                squad: squad,
                squadData: data)
            logMessage("PAK_damagedPoints .getShips() \(x)")
            
            state.faction.shipPilots = x
        
        case .updateFavorites(let showFavorites):
            showFavoritesOnly = showFavorites
            return loadAllSquads()
        
        case .loadSquads:
            return environment
                .squadService
                .loadSquadsListRx()
                .replaceError(with: [])
                .map { .faction(action: .setSquads(squads: $0)) }
                .eraseToAnyPublisher()
        
        case let .setSquads(squads):
            measure(name: "factionReducer.setSquads") {
            setSquads(squads: squads)
            }
            
        case .deleteAllSquads:
            state.faction.squadDataList.forEach {
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
typealias SquadDataFilter = (SquadData) -> Bool

protocol IStore {
    associatedtype State
    associatedtype Action
    associatedtype Environment
    
    var state: State { get set }

    func send(_ action: Action)
}

class MockStore<State, Action, Environment> : ObservableObject, IStore {
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
    
    func send(_ action: Action) {
        let nextAction = reducer(&state, action, environment)

        nextAction
            .print("Store.send")
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}

class Store<State, Action, Environment> : ObservableObject {
//    @Published var state: State
    @Published var state: State {
        didSet {
            let s: MyAppState = state as! MyAppState
            logMessage("PAK_Wrong_Damage viewProperties.didSet \(s.faction.shipPilots)")
        }
        
        willSet {
            logMessage("PAK_Wrong_Damage viewProperties.willSet \(state)")
        }
    }
    
    private let environment: Environment
    private let reducer: Reducer<State, Action, Environment>
    private var cancellables = Set<AnyCancellable>()
    
    @Published var navigateBack: Void?
    
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
            .print("Store.send")
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
    
    func cancel() {
        cancellables.removeAll()
    }
}
