//
//  FactionSquadList.swift
//  DialControl
//
//  Created by Phil Kirby on 4/28/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

class FactionSquadListViewModel : ObservableObject {
    @Published var squadNames : [String] = []
    @Published var numSquads: Int = 0
    @Published var squadDataList: [SquadData] = []
    
    let faction: String
    let moc: NSManagedObjectContext
    
    init(faction: String, moc: NSManagedObjectContext) {
        self.faction = faction
        self.moc = moc
    }
    
    func loadSquadsList() {
        func initWithDummyNames() {
            self.squadNames = ["Worlds Champion 2019",
                               "SaiDuchessTurr3Academies",
                               "VaderSoontirEcho",
                               "VagabondMaarekFifthBrotherTurr"]
        }
        
        func loadSquadsListFromCoreData() {
            do {
                let fetchRequest = SquadData.fetchRequest()
                let fetchedObjects = try self.moc.fetch(fetchRequest) as! [SquadData]
                
                fetchedObjects.forEach{ squad in
                    self.squadDataList.append(squad)
                }
                
                self.numSquads = self.squadDataList.count
            } catch {
                print(error)
            }
        }
        
//        initWithDummyNames()
        loadSquadsListFromCoreData()
    }
    
    func deleteSquad(squad: SquadData) {
        do {
            try self.moc.delete(squad)
        } catch {
            print(error)
        }
    }
}

struct FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    
    @ObservedObject var viewModel: FactionSquadListViewModel
    
    init(viewModel: FactionSquadListViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            headerView
                .padding(5)
            
//            squadList
            squadList_New
            
            Spacer()
        }
    }
    
    var titleView: some View {
        Text("\(self.viewModel.faction)")
            .font(.largeTitle)
    }
    
    var headerView: some View {
        HStack {
            Button(action: {
                self.viewFactory.viewType = .factionFilterView(.galactic_empire)
            }) {
                Text("Filter")
            }
            
            Spacer()
            titleView
            Spacer()
            
            Button(action: {
                self.viewFactory.viewType = .squadImportView
            }) {
                Text("Import XWS")
            }
        }
    }
    
    var squadList: some View {
        VStack {
            ForEach(self.viewModel.squadDataList, id:\.self) { squadData in
                FactionSquadCard(viewModel: FactionSquadCardViewModel(squadData: squadData)).environmentObject(self.viewFactory)
            }
        }
        .padding(10)
        .onAppear {
            self.viewModel.loadSquadsList()
        }
    }
    
    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    var shipsSection: some View {
        Section {
            ForEach(self.viewModel.squadDataList, id:\.self) { squadData in
                FactionSquadCard(viewModel: FactionSquadCardViewModel(squadData: squadData)).environmentObject(self.viewFactory)
            }
        }
    }
    
    var squadList_New: some View {
        List {
            if self.viewModel.squadDataList.isEmpty {
                emptySection
            } else {
                shipsSection
            }
        }
        .padding(10)
        .onAppear {
            self.viewModel.loadSquadsList()
        }
    }
}

class FactionSquadCardViewModel : ObservableObject {
    let points: Int = 150
    let theme: Theme = WestworldUITheme()
    let squadData: SquadData
    
    init(squadData: SquadData) {
        self.squadData = squadData
    }
    
    private func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString)
    }
    
    var buttonBackground: Color {
        theme.BUTTONBACKGROUND
    }
    
    var textForeground: Color {
        theme.TEXT_FOREGROUND
    }
    
    var border: Color {
        theme.BORDER_INACTIVE
    }
    
    var json: String {
        squadData.json ?? ""
    }
    
    var squad: Squad {
        if let json = squadData.json {
            return loadSquad(jsonString: json)
        }
        
        return Squad.emptySquad
    }
    

}

struct FactionSquadCard: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let viewModel: FactionSquadCardViewModel
    
    init(viewModel: FactionSquadCardViewModel) {
        self.viewModel = viewModel
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var pointsView: some View {
        Text("\(viewModel.squad.points)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var nameView: some View {
        HStack {
            Text(viewModel.squad.name)
                .font(.title)
                .lineLimit(1)
                .foregroundColor(viewModel.textForeground)
        }
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
    }
    
    var deleteButton: some View {
        Button(action: {
        }) {
            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundColor(Color.red)
        }
    }
    
    var squadButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadViewPAK(self.viewModel.squad)
        }) {
            ZStack {
                background
                pointsView.offset(x: -350, y: 0)
                nameView
                deleteButton.offset(x: 350, y: 0)
            }
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            squadButton
            Spacer()
        }
    }
}
