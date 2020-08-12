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

class SquadXWSImportViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    private let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString) { errorString in
            self.alertText = errorString
            self.showAlert = true
        }
    }
    
    func saveSquad(jsonString: String, name: String) -> SquadData {
        let squadData = SquadData(context: self.moc)
        squadData.id = UUID()
        squadData.name = name
        squadData.json = jsonString
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
        
        return squadData
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
    func createPilotState(squad: Squad, squadData: SquadData) {
        // for each pilot in squad.pilots
        for pilot in squad.pilots {
            // get the ship
            let shipPilot: ShipPilot = getShip(squad: squad, squadPilot: pilot)
            
            // Calculate new adjusted values based on upgrades (Hull Upgrade, Delta-7B, etc.)
            
            let arc = shipPilot.arcStats
            let agility = shipPilot.agilityStats
            
            let pilotStateData = PilotStateData(
                adjusted_attack: arc,
                adjusted_defense: agility,
                hull_active: shipPilot.hullStats,
                hull_inactive: 0,
                shield_active: shipPilot.shieldStats,
                shield_inactive: 0,
                force_active: shipPilot.forceStats,
                force_inactive: 0,
                charge_active: shipPilot.chargeStats,
                charge_inactive: 0,
                selected_maneuver: "",
                shipID: "",
                upgradeStates: []
            )
            
            let json = PilotStateData.serialize(type: pilotStateData)
            savePilotState(squadID: squadData.id!, state: json)
        }
    }
    
    func savePilotState(squadID: UUID, state: String) {
        let pilotState = PilotState(context: self.moc)
        pilotState.id = UUID()
        pilotState.squadID = squadID
        pilotState.json = state
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
    }
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
                let squad = self.viewModel.loadSquad(jsonString: self.xws)
                
                if squad.name != Squad.emptySquad.name {
                    // Save the squad JSON to CoreData
                    let squadData = self.viewModel.saveSquad(jsonString: self.xws, name: squad.name ?? "")
                    
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

