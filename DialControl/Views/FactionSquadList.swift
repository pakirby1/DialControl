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
    let squadService: SquadServiceProtocol
    
    init(faction: String,
         moc: NSManagedObjectContext,
         squadService: SquadServiceProtocol)
    {
        self.faction = faction
        self.moc = moc
        self.squadService = squadService
    }
    
    

    func deleteSquad(squadData: SquadData) {
        self.squadService.deleteSquad(squadData: squadData)
        refreshSquadsList()
    }
    
    func updateSquad(squadData: SquadData) {
        self.squadService.updateSquad(squadData: squadData)
        refreshSquadsList()
    }
    
    func refreshSquadsList() {
        let showFavoritesOnly = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
        
        self.squadService.loadSquadsList() { squads in
            self.squadDataList.removeAll()

            squads.forEach{ squad in
                self.squadDataList.append(squad)
            }

            self.numSquads = self.squadDataList.count
        }
        
        if showFavoritesOnly {
            self.squadDataList = self.squadDataList.filter{ $0.favorite == true }
        }
    }
    
    func updateFavorites(showFavoritesOnly: Bool) {
        UserDefaults.standard.set(showFavoritesOnly, forKey: "displayFavoritesOnly")
        refreshSquadsList()
    }
}

struct FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @ObservedObject var viewModel: FactionSquadListViewModel
    @State var displayDeleteAllConfirmation: Bool = false
    @State var displayFavoritesOnly: Bool = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
    let printer: DeallocPrinter
    @EnvironmentObject var store: MyAppStore
    
    init(viewModel: FactionSquadListViewModel) {
        self.viewModel = viewModel
        self.printer = DeallocPrinter("damagedPoints FactionSquadList")
    }
    
    var body: some View {
        VStack {
            headerView
                .padding(5)
            
            squadList
            
            deleteAllButton
                .padding(10)
        }
    }
    
    var deleteAllButton: some View {
        Button(action: {
                if self.viewModel.squadDataList.count > 0 {
                    self.displayDeleteAllConfirmation = true
                }
            })
        {
            Text("Delete All Squads")
        }
    }
    
    var titleView: some View {
        Text("\(self.viewModel.faction)")
            .font(.largeTitle)
    }
    
    var favoritesFilterView: some View {
        Button(action: {
            self.displayFavoritesOnly.toggle()
            self.viewModel.updateFavorites(showFavoritesOnly: self.displayFavoritesOnly)
        }) {
            if (self.displayFavoritesOnly) {
                Text("Show All")
            } else {
                Text("Favorites Only")
            }
        }
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
            favoritesFilterView
            Spacer()
            
            Button(action: {
                self.viewFactory.viewType = .squadImportView
            }) {
                Text("Import XWS")
            }
        }
    }
    
    var emptySection: some View {
        Section {
            Text("No squads found")
        }
    }
    
    var shipsSection: some View {
        Section {
            ForEach(self.viewModel.squadDataList, id:\.self) { squadData in
                FactionSquadCard(viewModel: FactionSquadCardViewModel(
                    squadData: squadData,
                    deleteCallback: self.viewModel.deleteSquad,
                    updateCallback: self.viewModel.updateSquad)
                ).environmentObject(self.viewFactory)
            }
        }
    }
    
    var primaryButtonAction: () -> Void {
        get {
            func old() {
                _ = self.viewModel.squadDataList.map { self.viewModel.deleteSquad(squadData: $0)
                }
            }
            
            func new() {
                self.store.send(.faction(action: .deleteAllSquads))
            }
            
            return {
                if FeaturesManager.shared.isFeatureEnabled("MyRedux")
                {
                    new()
                } else {
                    old()
                }
            }
        }
    }
    
    var secondaryButtonAction: () -> Void {
        get {
            return self.cancelAction(title: "Delete") {
                self.displayDeleteAllConfirmation = false
            }
        }
    }
    
    func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void {
        return {
            print("Cancelled \(title)")
            callback()
        }
    }
    
    var squadList: some View {
        List {
            if self.viewModel.squadDataList.isEmpty {
                emptySection
            } else {
                shipsSection
            }
        }
//        .onReceive(self.store.$state) { state in
//            self.displayDeleteAllConfirmation = state.faction.displayDeleteAllSquadsConfirmation
//        }
        .padding(10)
        .onAppear {
            self.store.send(.faction(action: .loadSquads))
            self.viewModel.refreshSquadsList()
        }
        .alert(isPresented: $displayDeleteAllConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("All Squads?"),
                primaryButton: Alert.Button.default(Text("Delete"), action: primaryButtonAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: secondaryButtonAction)
            )
        }
    }
}

class FactionSquadCardViewModel : ObservableObject, DamagedSquadRepresenting
{
    let points: Int = 150
    let theme: Theme = WestworldUITheme()
    let squadData: SquadData
    let deleteCallback: (SquadData) -> ()
    let updateCallback: (SquadData) -> ()
    @Published var shipPilots: [ShipPilot] = []
    
    init(squadData: SquadData,
         deleteCallback: @escaping (SquadData) -> (),
         updateCallback: @escaping (SquadData) -> ())
    {
        self.squadData = squadData
        self.deleteCallback = deleteCallback
        self.updateCallback = updateCallback
        
        // Hack to fix damagedPoints being 0 after favorite tapped on squad
        self.loadShips()
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
    
    func loadShips() {
        logMessage("damagedPoints FactionSquadCardViewModel.loadShips() ")
        self.shipPilots = SquadCardViewModel.getShips(
            squad: self.squad,
            squadData: self.squadData)
        
        if self.shipPilots.count == 0 {
            print("No Ships in Squad")
        }
    }
    
    func favoriteTapped() {
        logMessage("damagedPoints FactionSquadCardViewModel.favoriteTapped()")
        squadData.favorite.toggle()
        updateCallback(squadData)
        loadShips()
    }
    
    func deleteSquad() {
        deleteCallback(squadData)
    }
}

struct FactionSquadCard: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @ObservedObject var viewModel: FactionSquadCardViewModel
    let symbolSize: CGFloat = 36.0
    @State var displayDeleteConfirmation: Bool = false
    @State var refreshView: Bool = false
    let printer: DeallocPrinter
    @EnvironmentObject var store: MyAppStore
    
    init(viewModel: FactionSquadCardViewModel) {
        self.viewModel = viewModel
        self.printer = DeallocPrinter("damagedPoints FactionSquadCard")
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var pointsView: some View {
        Text("\(viewModel.squad.points ?? 0)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var damagedPointsView: some View {
        Text("\(viewModel.damagedPoints)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.red)
            .clipShape(Circle())
    }
    
    /*
     For the common case of text-only labels, you can use the convenience initializer that takes a title string (or localized string key) as its first parameter, instead of a trailing closure:


     Button("Sign In", action: signIn)
     */
    var vendorView: some View {
        Button("\(viewModel.squad.vendor?.description ?? "")") {
            UIApplication.shared.open(URL(string: self.viewModel.squad.vendor?.link ?? "")!)
        }
    }
    
    var favoriteView: some View {
        Button(action: {
            logMessage("damagedPoints favoriteTapped")
            self.viewModel.favoriteTapped()
            
            self.store.send(.faction(action: .deleteSquad(self.viewModel.squadData)))
        }) {
            Image(systemName: self.viewModel.squadData.favorite ? "star.fill" :
            "star")
                .font(.title)
                .foregroundColor(Color.yellow)
        }
    }
    
    var factionSymbol: some View {
        let x: Faction? = Faction.buildFaction(jsonFaction: self.viewModel.squad.faction)
        let characterCode = x?.characterCode
        
        return Button(action: {
            UIApplication.shared.open(URL(string: self.viewModel.squad.vendor?.link ?? "")!)
        }) {
            Text(characterCode ?? "")
                .font(.custom("xwing-miniatures", size: self.symbolSize))
        }
    }
    
    var nameView: some View {
        HStack {
            Text(viewModel.squad.name ?? "Unnamed")
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
    
    @ViewBuilder
    private var firstPlayerView: some View {
        if self.viewModel.squadData.firstPlayer == true {
            firstPlayerSymbol
        } else {
            EmptyView()
        }
    }
    
    var squadButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadViewPAK(self.viewModel.squad, self.viewModel.squadData)
        }) {
            ZStack {
                background
                factionSymbol.offset(x: -370, y: 0)
                pointsView.offset(x: -310, y: 0)
                damagedPointsView.offset(x: -230, y: 0)
                favoriteView.offset(x: 300, y: 0)
                firstPlayerView.offset(x: 260, y: 0)
                nameView
                deleteButton.offset(x: 350, y: 0)
            }
        }
    }
    
    var primaryButtonAction: () -> Void {
        get {
            func old() {
                self.viewModel.deleteSquad()
            }
            
            func new() {
//                self.store.send(.faction(action: .deleteAllSquads))
                self.store.send(.faction(action: .deleteAllSquads))
            }
            
            return {
                if FeaturesManager.shared.isFeatureEnabled("MyRedux")
                {
                    new()
                } else {
                    old()
                }
            }
        }
    }
    
    var secondaryButtonAction: () -> Void {
        get {
            return self.cancelAction(title: "Delete") {
                self.displayDeleteConfirmation = false
            }
        }
    }
    
    func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void {
        return {
            print("Cancelled \(title)")
            callback()
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
                primaryButton: Alert.Button.default(Text("Delete"), action: primaryButtonAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: secondaryButtonAction)
            )
        }
        .onAppear() {
            // The view body has been previously executed so the
            // view body needs to be recreated after onAppear
            // This can be done by updating an @State property, or
            // observing an @Published property.
            print("\(Date()) damagedPoints FactionSquadCard.onAppear()")
            self.viewModel.loadShips()
        }
    }
}
