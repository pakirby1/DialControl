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
import TimelaneCombine
import UIKit

// MARK:- MyAppState
struct MyAppState {
    var faction: FactionSquadListState
    var squad: MySquadViewState
    var ship: MyShipViewState
    var xwsImport: MyXWSImportViewState
    var factionFilter: FactionFilterState
    var tools: ToolsViewState
    var upgrades: UpgradesState
}

struct UpgradesState {
    var upgrades: [String: Array<Upgrade>] = [:]
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
    var pilotState: PilotState?
    var pilotStateData: PilotStateData?
    var shipImageURL: String = ""
}

struct MySquadViewState {
    var shipPilots: [ShipPilot] = []
    var squad: Squad?
    var squadData: SquadData?
    var cancellables = Set<AnyCancellable>()
    var wonCount: Count = Count.zero
    var lostCount: Count = Count.zero
}

struct FactionSquadListState {
    var squadDataList: [SquadData] = []
    var displayDeleteAllSquadsConfirmation: Bool = false
    var faction: String = ""
    var numSquads: Int {
        return squadDataList.count
    }
    
    var shipPilots: [ShipPilot] = []
    var currentRound: Int = 0
}

// MARK:- MyAppAction
enum MyAppAction {
    case faction(action: MyFactionSquadListAction)
    case squad(action: MySquadAction)
    case ship(action: MyShipAction)
    case xwsImport(action: MyXWSImportAction)
    case factionFilter(action: MyFactionFilterListAction)
    case tools(action: ToolsAction)
    case upgrades(action: UpgradesAction)
    case none
}

enum UpgradesAction {
    case setUpgrades(String, Array<Upgrade>)
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
    case setShips([ShipPilot])
    case flipDial(PilotStateData, PilotState)
    case flipDialFix(Squad, SquadData, PilotStateData, PilotState)
}

extension MySquadAction : CustomStringConvertible {
    var description: String {
        switch(self) {
            case let .getShips(squad, _):
                return "MySquadAction.getShips( \(String(describing: squad.name)), )"
            case let .updatePilotState(psd, _):
                let shipColor = psd.shipID
                return "hasSystemPhaseAction \(shipColor) \(String(describing: psd.hasSystemPhaseAction))"
            case let .updateSquad(squadData) :
                return "MySquadAction.updateSquad( \(String(describing: squadData.name)) )"
            case let .flipDial(psd, _):
                return "MySquadAction.flipDial( \(psd.pilot_index) )"
            case let .flipDialFix(_, _, psd, _):
                return "MySquadAction.flipDial( \(psd.pilot_index) )"
            case let .setShips(shipPilots):
                return "MySquadAction.setShips( shipCount: \(String(describing: shipPilots.count)) )"
        }
    }
}

enum MyFactionSquadListAction {
    case loadSquads
    case setSquads(squads: [SquadData])
    case deleteAllSquads
    case deleteSquad(SquadData)
    case updateSquad(SquadData)
    case favorite(Bool, SquadData)
    case updateFavorites(Bool)
    case getShips(SquadData)
    case setShips(SquadData, [ShipPilot])
    case setRound(Int)
    case loadRound
}

protocol NameDescribable {
    var typeName: String { get }
    static var typeName: String { get }
}

extension NameDescribable {
    var typeName: String {
        return String(describing: type(of: self))
    }

    static var typeName: String {
        return String(describing: self)
    }
}

var noAction : AnyPublisher<MyAppAction, Never> {
    return Empty().eraseToAnyPublisher()
}

extension MyFactionSquadListAction : CustomStringConvertible, NameDescribable {
    var description: String {
        switch(self) {
            case .loadSquads:
                return "\(self.typeName).loadSquads"
            case let .setSquads(squads):
                return "\(self.typeName).setSquads \(squads.count)"
            case .deleteAllSquads:
                return "\(self.typeName).deleteAllSquads"
            case let .deleteSquad(squadData):
                return "\(self.typeName).deleteSquad(\(String(describing: squadData.name)))"
            case let .updateSquad(squadData):
                return "\(self.typeName).updateSquad(\(String(describing: squadData.name)))"
            case let .favorite(isFavorite, squadData):
                return "\(self.typeName).favorite(\(isFavorite) \(String(describing: squadData.name)))"
            case let .updateFavorites(isFavorite):
                return "\(self.typeName).updateFavorites(\(isFavorite))"
            case let .getShips(squadData):
                return "\(self.typeName).getShips(\(String(describing: squadData.name)))"
            case let .setShips(squadData, shipPilots):
                return "\(self.typeName).setShips(\(String(describing: squadData.name)), \(shipPilots) pilots"
            case let .setRound(round):
                return "\(self.typeName).setRound(\(round))"
            case .loadRound:
                return "\(self.typeName).loadRound"
        }
    }
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
        case .upgrades(let action):
            print(action)
            return upgradesReducer(state: &state.upgrades,
                                action: action,
                                environment: environment)
            
        case .tools(let action):
            print(action)
            return toolsReducer(state: &state.tools,
                                action: action,
                                environment: environment)
            
        case .faction(let action):
            print("MyAppAction.faction \(action)")
            return factionReducer(state: &state,
                           action: action,
                           environment: environment)
        
        case .squad(let action):
            print("setSystemPhaseState \(action)")
            return squadReducer(state: &state.squad,
                                  action: action,
                                  environment: environment)
        
        case .ship(let action):
            print("MyAppAction.ship \(action)")
            return shipReducer(state: &state.ship,
                              action: action,
                              environment: environment)
        
        case .xwsImport(let action):
            print("MyAppAction.xwsImport \(action)")
            return xwsImportReducer(state: &state.xwsImport,
                               action: action,
                               environment: environment)
        
        case .factionFilter(let action):
            print("MyAppAction.factionFilter \(action)")
            return factionFilterReducer(state: &state.factionFilter,
                                        action: action,
                                        environment: environment)
        case .none:
            print("MyAppAction.none")
            return noAction
    }
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

func upgradesReducer(state: inout UpgradesState,
                     action: UpgradesAction,
                     environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case let .setUpgrades(category, upgrades):
            state.upgrades[category] = upgrades
            return noAction
    }
}

func toolsReducer(state: inout ToolsViewState,
                 action: ToolsAction,
                 environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case .deleteImageCache:
            return noAction
        
        case .downloadAllImages:
            state.message = ""
            return environment
                .imageService
                .downloadAllImages()
                .map(buildSetDownloadEvent(result:))
                .eraseToAnyPublisher()
 
        case .cancelDownloadAllImages:
            return noAction
            
        case .setCancelDownloadAllImages(let event):
            state.message = event.description
            return noAction
            
        case .setDownloadEvent(let event):
            state.currentImage = event
            return noAction
    }
}

func factionFilterReducer(state: inout FactionFilterState,
                          action: MyFactionFilterListAction,
                          environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case .loadFactions:
            return noAction
            
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

            return noAction
            
        case .deselectFaction(_):
            return noAction
        case .deselectAll:
            return noAction
    }
}

enum XWSImportError: Error {
    case squadNameNotFound
    case unexpected(code: Int)
}

extension XWSImportError : LocalizedError {
    public var errorDescription: String? {
        switch(self) {
            case .squadNameNotFound :
                return NSLocalizedString(
                    "No squad name specified",
                    comment: "Invalid Squad Name"
                )
            case .unexpected(let code) :
                return NSLocalizedString(
                    "Code \(code)",
                    comment: "Error"
                )
        }
    }
}

func xwsImportReducer(state: inout MyXWSImportViewState,
                      action: MyXWSImportAction,
                      environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never> {
    func importXWS(xws: inout String) -> AnyPublisher<MyAppAction, Never> {
        func updateSquadPilotsWithStandardLoadoutUpgrades(squad: inout Squad) {
            // Since we can't update squad.pilots while iterating over squad.pilots
            var updatedPilotsWithStandardLoadoutUpgrades : [SquadPilot] = []
        
            for var pilot in squad.pilots {
                var shipJSON: String = ""
                shipJSON = getJSONFor(ship: pilot.ship, faction: squad.faction)
                
                do {
                    let ship: Ship = try Ship.deserializeJSON(jsonString: shipJSON)
                    /*
                     Check if we have a list of upgrade names in standardLoadout field of pilot
                     
                     Get the pilot by pilotId
                     Get the standardLoadout field for this pilot -> ["marksmanship", "hate", "afterburners"]
                     Build an [Upgrade] from this ["marksmanship", "hate", "afterburners"]
                     */
                    if let standardLoadoutUpgrades = ship.pilotStandardLoadoutUpgrades(pilotId: pilot.id)
                    {
                        /*
                         if the ship has standardLoadout upgrades, then build a SquadPilotUpgrade from
                         the standardLoadout upgrades.  and set squadPilot.upgrades to the SquadPilotUpgrade
                         
                         if standardLoadout is
                         "standardLoadout": ["marksmanship", "hate", "afterburners"]
                         
                         create
                         "talent":["marksmanship"],"modification":["afterburners"],"forcepower":["hate"]
                         
                         {"talent":["deadeyeshot","marksmanship"],"modification":["shieldupgrade"]}
                         
                         */
                        let squadPilotUpgrades : Dictionary<String, [String]> = UpgradeUtility.getUpgradesDictionary(upgradeXWSArray: standardLoadoutUpgrades)
                        
                        // serialize the dictionary into a SquadPilotUpgrade object and update
                        // the pilot with the new SquadPilotUpgrade
                        pilot.upgrades = SquadPilotUpgrade.loadFrom(dictionary: squadPilotUpgrades)
                        updatedPilotsWithStandardLoadoutUpgrades.append(pilot)
                    } else {
                        // Normal pilot with upgrades
                        updatedPilotsWithStandardLoadoutUpgrades.append(pilot)
                    }
                } catch {
                    return
                }
            }

            // Update squad.pilots with the array of updated pilots
            squad.pilots = updatedPilotsWithStandardLoadoutUpgrades
        }
        
        do {
            var squad = try environment.squadService.loadSquad_throws(jsonString: &xws)
            
            updateSquadPilotsWithStandardLoadoutUpgrades(squad: &squad)
            var updatedXWS = squad.getJSON() ?? ""
            var updatedSquad = try environment.squadService.loadSquad_throws(jsonString: &updatedXWS)
            
            if updatedSquad.name != Squad.emptySquad.name {
                // Build squad data
                var squadData = environment.squadService.buildSquadData(jsonString: updatedXWS, name: updatedSquad.name ?? "")
                
                // create the pilot state & update the squad
                try environment.pilotStateService.createPilotState_throws(squad: &updatedSquad, squadData: squadData)
            
                return Just<MyAppAction>(.xwsImport(action: .importSuccess))
                    .eraseToAnyPublisher()
            } else {
                throw XWSImportError.squadNameNotFound
            }
        } catch XWSImportError.squadNameNotFound {
            let alertText = environment.squadService.alertText
            return Just<MyAppAction>(.xwsImport(action: .displayAlert(alertText)))
                .eraseToAnyPublisher()
        }
        catch {
            print(error.localizedDescription)
            return Just<MyAppAction>(.xwsImport(action: .displayAlert(error.localizedDescription)))
                .eraseToAnyPublisher()
        }
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
    
    return noAction
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
    
    func handleDestroyed(_ pilotStateData: inout PilotStateData) {
        let current = pilotStateData.dial_status
        
        /*
         case hidden
         case revealed
         case set
         case destroyed
         case ionized
         
         current        $0.isDestroyed  new Status
         .hidden        false           .hidden
         .hidden        true            .destroyed
         .revealed      false           .revealed
         .revealed      true            .destroyed
         .set           false           .set
         .set           true            .destroyed
         .destroyed     false           .set
         .destroyed     true            .destroyed
         .ionized       false           .ionized
         .ionized       true            .destroyed
         */
        
        if pilotStateData.isDestroyed {
            pilotStateData.dial_status = .destroyed
        } else if (current == .destroyed) {
            // we were destroyed but no longer destroyed so we are now .set
            pilotStateData.dial_status = .set
        }
    }
    
    func updateHull(_ active: Int, _ inactive: Int) {
        print(active, inactive)
        update(psdHandler: {
            $0.updateHull(active: active, inactive: inactive)
            handleDestroyed(&$0)
        })
    }
    
    func updateShield(_ active: Int , _ inactive: Int ) {
        print(active, inactive)
        update(psdHandler: {
            $0.updateShield(active: active, inactive: inactive)
            handleDestroyed(&$0)
        })
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

    /*
    // Async version
//    func update() async -> PilotStateData {
//        await withCheckedContinuation{ continuation in
//            update { psd in
//                continuation.resume(with: &psd)
//            }
//
//        }
//    }
     
     
     */
    
    
    
    /*
    func updatePSD(completion: @escaping (Result<PilotStateData, Error>) -> Void) {
        Task {
            do {
                let psd = try await updatePSD()
                completion(.success(psd))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    @Sendable func updatePSD() async throws -> PilotStateData {
        do {
            if let psd = state.pilotStateData {
                return psd
            }
        }
        catch {
            throw Error(error)
        }
    }
     */
    
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
                                  faction: squad.faction).1.image
        
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
    
    return noAction
}

func squadReducer(state: inout MySquadViewState,
                    action: MySquadAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    switch(action) {
        case let .flipDialFix(squad, squadData, pilotStateData, pilotState):
            pilotStateData.change(update: {
                var newPSD = $0
                
                newPSD.dial_status.handleEvent(event: .dialTapped)
                
                environment
                    .pilotStateService
                    .updateState(newData: newPSD, state: pilotState)
                
                print("\(Date()) PAK_\(#function) after pilotStateData id: \(String(describing: pilotState.id)) dial_status: \(newPSD.dial_status)")
            })
            
            return environment
                .squadService
                .getShips(squad: squad, squadData: squadData)
                .logShips(squadName: String(describing: squad.name))
                .map {
                    MyAppAction.squad(action: .setShips($0))
                }
                .eraseToAnyPublisher()
            
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
            measure(name: "setSystemPhaseState store.send.updatePilotState", {
                environment
                    .pilotStateService
                    .updateState(newData: pilotStateData, state: pilotState)
            })
        
        case let .getShips(squad, data):
            global_os_log("Store.send squadReducer.getShips", data.description)
            state.squad = squad
            state.squadData = data
            
            return measure("Performance", name: "squadReducer .getShips") { () -> AnyPublisher<MyAppAction, Never> in
                return environment
                    .squadService
                    .getShips(squad: data.squad, squadData: data)
                    .logShips(squadName: String(describing: squad.name))
                    .map {
                        MyAppAction.squad(action: .setShips($0))
                    }
                    .eraseToAnyPublisher()
            }

        case let .setShips(shipPilots):
            state.shipPilots = shipPilots
    }
    
    return noAction
}

func factionReducer(state: inout MyAppState,
                    action: MyFactionSquadListAction,
                    environment: MyEnvironment) -> AnyPublisher<MyAppAction, Never>
{
    @UserDefaultsBacked<Int>(key: "currentRound") var currentRound = 0

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

        measure(name: "favoriteTapped.setSquads") {
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
    }
    
    print("favoriteTapped: \(action)")
    
    var loadRoundAction : AnyPublisher<MyAppAction, Never> {
        Just(.faction(action: .loadRound)).eraseToAnyPublisher()
    }
    
    switch(action) {
        case let .setShips(data, shipPilots):
            measure("Performance", name: "factionReducer .setShips") {
                global_os_log("Store.send factionReducer.setShips", "shipPilots.count \(shipPilots.count)")
                state
                    .faction
                    .squadDataList
                    .setShips(data: data, shipPilots: shipPilots)
            }
            
        case let .getShips(data):
            global_os_log("Store.send factionReducer.getShips", data.description)
            
            measure("Performance", name: "factionReducer .getShips") {
                return environment
                    .squadService
                    .getShips(squad: data.squad, squadData: data)
                    .os_log(message: "Store.send MyFactionSquadListAction.getShips")
                    .replaceError(with: [])
                    .map {
                        MyAppAction.faction(action: .setShips(data, $0))
                    }
                    .os_log(message: "Store.send MyFactionSquadListAction.getShips.map")
                    .eraseToAnyPublisher()
            }

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
            setSquads(squads: squads)
            
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
            
        case let .setRound(round):
            // Persist to UserDefaults
            currentRound = round
            global_os_log("factionReducer.setRound(round)", "\(currentRound)")
            return loadRoundAction
            
        case .loadRound:
            state.faction.currentRound = currentRound
            global_os_log("factionReducer.loadRound", "\(currentRound)")
    }
    
    return noAction
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
    private(set) var publisher = PassthroughSubject<Action, Never>()
    
    init(state: State,
         reducer: @escaping Reducer<State, Action, Environment>,
         environment: Environment)
    {
        self.state = state
        self.reducer = reducer
        self.environment = environment
        
        publisher
            .lane("Store.publisher", transformValue: transform(action:))
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &cancellables)
    }
}

extension Store {
    func send(_ action: Action) {
        func send_old(_ action: Action) {
            measure(name: "setSystemPhaseState store.send")
            {
                // I was getting the message
                //Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                // the workaround is to wrap it in a DispatchQueue.main.async
                // https://developer.apple.com/forums/thread/711899
                DispatchQueue.main.async { [self] in
                    
                    let nextAction = reducer(&state, action, self.environment)
                    
                    nextAction
                        .eraseToAnyPublisher()
                        .print("Store.send")
                        .receive(on: DispatchQueue.main)
                        .sink(receiveValue: {
                            self.publisher.send($0)
                        })
                        .store(in: &cancellables)
                }
            }
        }
        
//        func send_new(_ action: Action) {
//            global_os_log("Store.send_new(\(action))")
//
//            Just(action)
//                .lane("send_new Just", filter: [.event], transformValue: transform(action:))
//                .flatMap{
//                    return self.reducer(&self.state, $0, self.environment)
//                }
//                .eraseToAnyPublisher()
//                .lane("send_new flatMap", filter: [.event], transformValue: transform(action:))
//                .receive(on: DispatchQueue.main)
//                .sink(receiveValue: { [weak self] in
//                    global_os_log("Store.send_new sink(\(action))")
//                    self?.publisher.send($0)
//                })
//                .store(in: &cancellables)
//        }
        
        send_old(action)
    }
    
    func transform(action: Action) -> String {
        let x = action as! MyAppAction
        
        switch(x) {
            case .faction(let act):
                return act.description
            case .squad(let act):
                return act.description
            case .ship(let act):
                return "MyShipAction \(act)"
            case .upgrades(let act):
                return "UpgradesAction \(act)"
            case .xwsImport(let act):
                return "MyXWSImportAction \(act)"
            case .tools(let act):
                return "ToolsAction \(act)"
            case .factionFilter(let act):
                return "MyFactionFilterListAction \(act)"
            default:
                return "Action is: \(action)"
        }
    }
    
    func cancel() {
        cancellables.removeAll()
    }
}
