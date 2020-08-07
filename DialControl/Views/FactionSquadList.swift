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
                
                self.squadDataList.removeAll()
                
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
            self.moc.delete(squad)
            try moc.save()
            self.loadSquadsList()
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
                self.viewFactory.viewType = .factionFilterView(.none)
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
    
//    var squadList: some View {
//        VStack {
//            ForEach(self.viewModel.squadDataList, id:\.self) { squadData in
//                FactionSquadCard(viewModel: FactionSquadCardViewModel(squadData: squadData)).environmentObject(self.viewFactory)
//            }
//        }
//        .padding(10)
//        .onAppear {
//            self.viewModel.loadSquadsList()
//        }
//    }
    
    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    var shipsSection: some View {
        Section {
            ForEach(self.viewModel.squadDataList, id:\.self) { squadData in
                FactionSquadCard(viewModel: FactionSquadCardViewModel(squadData: squadData, deleteCallback: self.viewModel.deleteSquad)).environmentObject(self.viewFactory)
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
    let deleteCallback: (SquadData) ->()
    
    init(squadData: SquadData, deleteCallback: @escaping (SquadData) -> ()) {
        self.squadData = squadData
        self.deleteCallback = deleteCallback
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
    let symbolSize: CGFloat = 36.0
    @State var displayDeleteConfirmation: Bool = false
    
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
    
    var vendorView: some View {
        Button("\(viewModel.squad.vendor.description)") {
            UIApplication.shared.open(URL(string: self.viewModel.squad.vendor.link)!)
        }
    }
    
    var favoriteView: some View {
        Button(action: {}) {
            Image(systemName: "star")
                .font(.title)
                .foregroundColor(Color.yellow)
        }
    }
    
    var factionSymbol: some View {
        let x: Faction? = Faction.buildFaction(jsonFaction: self.viewModel.squad.faction)
        let characterCode = x?.characterCode
        
        return Text(characterCode ?? "")
            .font(.custom("xwing-miniatures", size: self.symbolSize))
    }
    
    var nameView: some View {
        HStack {
            Text(viewModel.squad.name)
                .font(.title)
//                .lineLimit(1)
                .foregroundColor(viewModel.textForeground)
            
            
        }
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
    }
    
    var deleteButton: some View {
        Button(action: {
//            self.viewModel.deleteCallback(self.viewModel.squadData)
            self.displayDeleteConfirmation = true
        }) {
            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundColor(Color.white)
        }
    }
    
    var squadButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadViewPAK(self.viewModel.squad)
        }) {
            ZStack {
                background
                factionSymbol.offset(x: -370, y: 0)
                pointsView.offset(x: -310, y: 0)
                vendorView.offset(x: -250, y: 0)
                favoriteView.offset(x: 300, y: 0)
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
        }.alert(isPresented: $displayDeleteConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("\(self.viewModel.squadData.name ?? "Squad")"),
                primaryButton: Alert.Button.default(Text("Delete"), action: {
                    self.viewModel.deleteCallback(self.viewModel.squadData)
                }),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {
                    print("Cancelled Delete")
                })
            )
        }
    }
}
