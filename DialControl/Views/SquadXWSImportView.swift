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
    
    func saveSquad(jsonString: String, name: String) {
        let squadData = SquadData(context: self.moc)
        squadData.id = UUID()
        squadData.name = name
        squadData.json = jsonString
        
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
                    self.viewModel.saveSquad(jsonString: self.xws, name: squad.name)
                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
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

