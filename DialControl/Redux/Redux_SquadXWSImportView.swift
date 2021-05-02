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


class Redux_SquadXWSImportViewModel : ObservableObject {
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

struct Redux_SquadXWSImportView : View {
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

