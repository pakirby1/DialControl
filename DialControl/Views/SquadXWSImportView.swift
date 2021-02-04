//
//  SquadXWSImportView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class SquadXWSImportViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    let moc: NSManagedObjectContext
    let squadService: SquadServiceProtocol
    let pilotStateService: PilotStateServiceProtocol
    
    init(moc: NSManagedObjectContext,
         squadService: SquadServiceProtocol,
         pilotStateService: PilotStateServiceProtocol)
    {
        self.moc = moc
        self.squadService = squadService
        self.pilotStateService = pilotStateService
    }
    
    func loadSquad(jsonString: inout String) -> Squad {
        // replace janky yasb exported to remove '-' characters.
        jsonString = jsonString
            .replacingOccurrences(of: "force-power", with: "forcepower")
            .replacingOccurrences(of: "tactical-relay", with: "tacticalrelay")
        
        return Squad.serializeJSON(jsonString: jsonString) { errorString in
            self.alertText = errorString
            self.showAlert = true
        }
    }
    
    func saveSquad(jsonString: String, name: String) -> SquadData {
        return self.squadService.saveSquad(jsonString: jsonString, name: name)
    }
    
    func createPilotState(squad: Squad, squadData: SquadData) {
        self.pilotStateService.createPilotState(squad: squad, squadData: squadData)
    }
    
    /*
     struct UpgradeStateData {
         let force_active : Int?
         let force_inactive : Int?
         let charge_active : Int?
         let charge_inactive : Int?
         let selected_side : Int
     }

     struct PilotStateData {
         let adjusted_attack : Int
         let adjusted_defense : Int
         let hull_active : Int
         let hull_inactive : Int
         let shield_active : Int
         let shield_inactive : Int
         let force_active : Int
         let force_inactive : Int
         let charge_active : Int
         let charge_inactive : Int
         let selected_maneuver: String
         let shipID: String
         let upgradeStates : [UpgradeStateData]?
     }
     */
    
    
    
    
    
}

struct SquadXWSImportView : View {
    @State private var xws: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    @State var showAlert: Bool = false
    @State var alertText: String = ""
    @ObservedObject var viewModel: SquadXWSImportViewModel

    let textViewObserver: TextViewObservable = TextViewObservable()
    let lineHeight = UIFont.systemFont(ofSize: 17).lineHeight
    
    init(viewModel: SquadXWSImportViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.viewFactory.back()
                }) {
                    Text("< Back")
                }
                
                Spacer()
            }
            
            Text("Squad XWS Import")
                .font(.title)
            
            TextView(placeholderText: "Squad XWS", text: $xws)
                .padding(10)
                .frame(height: self.textViewObserver.height < 600 ? 600 : self.textViewObserver.height + lineHeight)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 1))
                .environmentObject(textViewObserver)
            
            Button(action: {
                let squad = self.viewModel.loadSquad(jsonString: &self.xws)
                
                if squad.name != Squad.emptySquad.name {
                    // Save the squad JSON to CoreData
                    let squadData = self.viewModel.saveSquad(jsonString: self.xws,
                                                             name: squad.name ?? "")
                    
                    // Create the state and save to PilotState
                    self.viewModel.createPilotState(squad: squad, squadData: squadData)
                    
//                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
                    self.viewFactory.back()
                }
            } ) {
                Text("Import")
            }
        }.padding(10)
            .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.alertText),
                  dismissButton: .default(Text("OK")))
        }
    }
}

// MARK:- Redux
class SquadXWSImportViewModel_New : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    let moc: NSManagedObjectContext
    let squadService: SquadServiceProtocol
    let pilotStateService: PilotStateServiceProtocol
    let store: Store
    
    init(moc: NSManagedObjectContext,
         squadService: SquadServiceProtocol,
         pilotStateService: PilotStateServiceProtocol,
         store: Store)
    {
        self.moc = moc
        self.squadService = squadService
        self.pilotStateService = pilotStateService
        self.store = store
    }
    
    func importSquad(jsonString: String) {
        store.send(action: ImportSquadAction(json: jsonString))
    }
    
    
    
    
    
    
    
    /*
     struct UpgradeStateData {
         let force_active : Int?
         let force_inactive : Int?
         let charge_active : Int?
         let charge_inactive : Int?
         let selected_side : Int
     }

     struct PilotStateData {
         let adjusted_attack : Int
         let adjusted_defense : Int
         let hull_active : Int
         let hull_inactive : Int
         let shield_active : Int
         let shield_inactive : Int
         let force_active : Int
         let force_inactive : Int
         let charge_active : Int
         let charge_inactive : Int
         let selected_maneuver: String
         let shipID: String
         let upgradeStates : [UpgradeStateData]?
     }
     */
    
    
    
    
    
}

struct SquadXWSImportView_New : View {
    @State private var xws: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    @State var showAlert: Bool = false
    @State var alertText: String = ""
    @ObservedObject var viewModel: SquadXWSImportViewModel_New

    let textViewObserver: TextViewObservable = TextViewObservable()
    let lineHeight = UIFont.systemFont(ofSize: 17).lineHeight
    
    init(viewModel: SquadXWSImportViewModel_New) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.viewModel.importSquad(jsonString: self.xws)
                    self.viewFactory.back()
                }) {
                    Text("< Back")
                }
                
                Spacer()
            }
            
            Text("Squad XWS Import")
                .font(.title)
            
            TextView(placeholderText: "Squad XWS", text: $xws)
                .padding(10)
                .frame(height: self.textViewObserver.height < 600 ? 600 : self.textViewObserver.height + lineHeight)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 1))
                .environmentObject(textViewObserver)
            
            Button(action: {
                self.viewModel.importSquad(jsonString: self.xws)
                
//                if squad.name != Squad.emptySquad.name {
//                    // Save the squad JSON to CoreData
//                    let squadData = self.viewModel.saveSquad(jsonString: self.xws,
//                                                             name: squad.name ?? "")
//
//                    // Create the state and save to PilotState
//                    self.viewModel.createPilotState(squad: squad, squadData: squadData)
//
////                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
//                    self.viewFactory.back()
//                }
            } ) {
                Text("Import")
            }
        }.padding(10)
            .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.alertText),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct ImportSquadAction : ActionProtocol {
    let json: String
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error>
    {
        return loadSquad(jsonString: json)
            .map{ squad -> ActionProtocol in
                let name = squad.name ?? ""
                return SaveSquadAction(json: self.json, squad: squad)
            }
            .tryCatch { error -> AnyPublisher<ActionProtocol, Error> in
                throw XWSImportError.serializationError("loadSquad")
            }
            .eraseToAnyPublisher()
    }
    
    private func loadSquad(jsonString: String) -> AnyPublisher<Squad, Error>
    {
        return Future<Squad, Error>{ promise in
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
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error> {
        return environment.squadsService.saveSquad(jsonString: self.json, name: self.squadName)
            .map{ squadData -> ActionProtocol in
                let action = CreatePilotStateAction(json: self.json,
                                                    squadName: self.squadName,
                                                    squad: self.squad,
                                                    squadData: squadData)
                
                return action
            }.eraseToAnyPublisher()
        
        return Empty().eraseToAnyPublisher()
    }
}

struct CreatePilotStateAction: ActionProtocol {
    let json: String
    let squadName: String
    let squad: Squad
    let squadData: SquadData
    
    func execute(state: inout AppState, environment: AppEnvironment) -> AnyPublisher<ActionProtocol, Error> {
        environment.pilotStateService.createPilotState(squad: squad, squadData: squadData)
        
        return Empty().eraseToAnyPublisher()
    }
}
