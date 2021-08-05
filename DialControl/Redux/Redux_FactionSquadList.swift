//
//  Redux_FactionSquadList.swift
//  DialControl
//
//  Created by Phil Kirby on 3/11/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

struct Redux_FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    
    @State var displayDeleteAllConfirmation: Bool = false
    @State var displayFavoritesOnly: Bool = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
    
    let faction: String
    
    // Dealloc tracker
    let printer: DeallocPrinter
    
    init(faction: String) {
        self.faction = faction
        self.printer = DeallocPrinter("damagedPoints FactionSquadList")
    }
    
    var squadDataList : [SquadData] {
        get {
            let list = self.store.state.faction.squadDataList
            logMessage("damagedPoints list \(list)")
            return list
        }
    }
    
    var body: some View {
        VStack {
            headerView
                .padding(5)
            
            squadList
            
            footerView
        }
    }
    
    var footerView: some View {
        HStack {
            toolsButton
                .padding(10)
        }
    }
    
    var toolsButton: some View {
        Button(action: {
            self.viewFactory.viewType = .toolsView
        })
        {
            Image(systemName: "wrench.and.screwdriver")
                .foregroundColor(.white)
                .font(.largeTitle)
        }
    }

    var titleView: some View {
        Text(self.store.state.factionFilter.selectedFaction.rawValue)
            .font(.title)
    }
    
    var favoritesFilterView: some View {
        Button(action: {
            self.displayFavoritesOnly.toggle()
            self.updateFavorites(showFavoritesOnly: self.displayFavoritesOnly)
        }) {
            self.displayFavoritesOnly ? Text("Show All") : Text("Favorites Only")
        }
    }
    
    var headerView: some View {
        HStack {
            Button(action: {
                self.viewFactory.viewType = .factionFilterView
            }) {
//                Text("Filter")
                Image(systemName: "line.horizontal.3.decrease.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 48, weight: .bold))
            }
            
            titleView
            Spacer()
            favoritesFilterView
            Spacer()
            xwsImportButton
        }
    }
    
    var xwsImportButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadImportView
        }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 48, weight: .bold))
        }
    }
    
    var emptySection: some View {
        Section {
            Text("No squads found")
        }
    }
    
    var shipsSection: some View {
        Section {
            ForEach(squadDataList, id:\.self) { squadData in
                Redux_FactionSquadCard(squadData: squadData,
                                       deleteCallback: self.deleteSquad,
                                       updateCallback: self.updateSquad)
                .environmentObject(self.viewFactory)
                .environmentObject(self.store)
            }
        }
    }
    
    var deleteAllAlertAction: () -> Void {
        get {
            func old() {
                _ = squadDataList.map { self.deleteSquad(squadData: $0)
                }
            }
            
            func new() {
                self.store.send(.faction(action: .deleteAllSquads))
            }
            
            return {
                if FeaturesManager.shared.isFeatureEnabled(.MyRedux)
                {
                    new()
                } else {
                    old()
                }
            }
        }
    }
    
    var cancelAlertAction: () -> Void {
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
            if squadDataList.isEmpty {
                emptySection
            } else {
                shipsSection
            }
        }
        .padding(10)
        .onAppear {
            self.refreshSquadsList()
        }
        .alert(isPresented: $displayDeleteAllConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("All Squads?"),
                primaryButton: Alert.Button.default(Text("Delete"), action: deleteAllAlertAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: cancelAlertAction)
            )
        }
    }
}

extension Redux_FactionSquadList {
    func deleteSquad(squadData: SquadData) {
        self.store.send(.faction(action: .deleteSquad(squadData)))
        refreshSquadsList()
    }

    func updateSquad(squadData: SquadData) {
        self.store.send(.faction(action: .updateSquad(squadData)))
        refreshSquadsList()
    }

    func refreshSquadsList() {
        self.store.send(.faction(action: .loadSquads))
    }

    func updateFavorites(showFavoritesOnly: Bool) {
        self.store.send(.faction(action: .updateFavorites(showFavoritesOnly)))
        refreshSquadsList()
    }
}

struct Redux_FactionSquadCardViewModel
{
    let points: Int = 150
    let theme: Theme = WestworldUITheme()
    let symbolSize: CGFloat = 36.0
    
    var buttonBackground: Color {
        theme.BUTTONBACKGROUND
    }
    
    var textForeground: Color {
        theme.TEXT_FOREGROUND
    }
    
    var border: Color {
        theme.BORDER_INACTIVE
    }
}

struct Redux_FactionSquadCard: View, DamagedSquadRepresenting  {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    let viewModel: Redux_FactionSquadCardViewModel = Redux_FactionSquadCardViewModel()
    
    @State var displayDeleteConfirmation: Bool = false
    @State var refreshView: Bool = false
    
    let printer: DeallocPrinter
    
    let deleteCallback: (SquadData) -> ()
    let updateCallback: (SquadData) -> ()
    let squadData: SquadData
    
    init(squadData: SquadData,
         deleteCallback: @escaping (SquadData) -> (),
         updateCallback: @escaping (SquadData) -> ())
    {
        self.deleteCallback = deleteCallback
        self.updateCallback = updateCallback
        self.squadData = squadData
        self.printer = DeallocPrinter("damagedPoints FactionSquadCard")
    }
    
    private func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString)
    }
    
    func loadShips() {
        logMessage("PAK_damagedPoints Redux_FactionSquadCardViewModel.loadShips() ")
        
        store.send(.faction(action: .getShips(self.squad, self.squadData)))
        
        if store.state.faction.shipPilots.count == 0 {
            print("No Ships in Squad")
        }
    }
    
    func favoriteTapped() {
        logMessage("damagedPoints Redux_FactionSquadCardViewModel.favoriteTapped()")
        squadData.favorite.toggle()
        updateCallback(squadData)
        loadShips()
    }
    
    func deleteSquad() {
        deleteCallback(squadData)
    }
    
    var shipPilots: [ShipPilot] {
        get {
            logMessage("damagedPoints shipPilots: \(self.store.state.faction.shipPilots)")
            return self.store.state.faction.shipPilots
        }
        set {

        }
    }
    
    var json: String {
        squadData.json ?? ""
    }
    
    var squad: Squad {
        if let json = squadData.json {
            logMessage("damagedPoints json: \(json)")
            return loadSquad(jsonString: json)
        }
        
        return Squad.emptySquad
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var pointsView: some View {
        Text("\(squad.points ?? 0)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var damagedPointsView: some View {
        logMessage("PAK_Wrong_Damage damagedPointsView")
        
        return Text("\(damagedPoints)")
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
        Button("\(self.squad.vendor?.description ?? "")") {
            UIApplication.shared.open(URL(string: self.squad.vendor?.link ?? "")!)
        }
    }
    
    var favoriteView: some View {
        Button(action: {
            logMessage("damagedPoints favoriteTapped")
            self.favoriteTapped()
            
            let action: MyFactionSquadListAction = .favorite(self.squadData.favorite, self.squadData)
            self.store.send(.faction(action: action))
        }) {
            Image(systemName: self.squadData.favorite ? "star.fill" :
            "star")
                .font(.title)
                .foregroundColor(Color.yellow)
        }
    }
    
    var factionSymbol: some View {
        let faction: Faction? = Faction.buildFaction(jsonFaction: squad.faction)
        let characterCode = faction?.characterCode
        
        return Button(action: {
            UIApplication.shared.open(URL(string: self.squad.vendor?.link ?? "")!)
        }) {
            Text(characterCode ?? "")
                .font(.custom("xwing-miniatures", size: self.viewModel.symbolSize))
        }
    }
    
    var nameView: some View {
        HStack {
            Text(squad.name ?? "Unnamed")
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
            self.displayDeleteConfirmation = true
        }) {
            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundColor(Color.white)
        }.alert(isPresented: $displayDeleteConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("\(self.squadData.name ?? "Squad")"),
                primaryButton: Alert.Button.default(Text("Delete"), action: deleteAlertAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: cancelAlertAction)
            )
        }
    }
    
    @ViewBuilder
    private var firstPlayerView: some View {
        if self.squadData.firstPlayer == true {
            firstPlayerSymbol
        } else {
            EmptyView()
        }
    }
    
    var squadButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadViewPAK(self.squad, self.squadData)
        }) {
            ZStack {
                background
                factionSymbol.offset(x: -370, y: 0)
                pointsView.offset(x: -310, y: 0)
                damagedPointsView.offset(x: -230, y: 0)
                nameView
                firstPlayerView.offset(x: 260, y: 0)
                favoriteView.offset(x: 300, y: 0)
                deleteButton.offset(x: 350, y: 0)
            }
        }
    }
    
    var deleteAlertAction: () -> Void {
        get {
            func old() {
                self.deleteSquad()
            }
            
            func new() {
                self.store.send(.faction(action: .deleteSquad(self.squadData)))
            }
            
            return {
                if FeaturesManager.shared.isFeatureEnabled(.MyRedux)
                {
                    new()
                } else {
                    old()
                }
            }
        }
    }
    
    var cancelAlertAction: () -> Void {
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
        }
        .onAppear() {
            // The view body has been previously executed so the
            // view body needs to be recreated after onAppear
            // This can be done by updating an @State property, or
            // observing an @Published property.
            logMessage("PAK_Wrong_Damage FactionSquadCard.onAppear()")
            
            // Have to call in .onAppear because the @EnvironmentObject store
            // is not available until AFTER init() is called
            self.loadShips()
            
            // inject the AppStore into the view model here since
            // @EnvironmentObject isn't accessible in the init()
        }
    }
}
