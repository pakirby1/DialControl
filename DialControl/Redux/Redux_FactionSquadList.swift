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
import Combine

struct Redux_FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    var store: MyAppStore
    
    @State var displayDeleteAllConfirmation: Bool = false
    @State var displayFavoritesOnly: Bool = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
    @State var displayResetRoundCounter: Bool = false
    
    @DataBacked(key: "CoreDataTest", storage: CoreDataStorage()) var test: SquadData = SquadData.init()
    
    @DataBacked(key: "UserDefaultsTest", storage: CombineStorage(initialValue: 0)) var combineTest : Int = 0
    
    let faction: String
    
    // Dealloc tracker
    let printer: DeallocPrinter
    
    @ObservedObject var viewModel: Redux_FactionSquadListViewModel
    
    init(faction: String, store: MyAppStore) {
        self.store = store
        self.faction = faction
        self.viewModel = Redux_FactionSquadListViewModel(store: store)
        self.printer = DeallocPrinter("damagedPoints FactionSquadList")
    }
    
    var progressView : some View {
        switch(self.viewModel.viewProperties.loadingState) {
            case .pending:
                return Text("Pending")
            default:
                return Text("")
        }
    }
    
    var squadDataList : [SquadData] {
        get {
            let list = self.store.state.faction.squadDataList
            logMessage("damagedPoints list \(list)")
            return list
        }
    }
    
    var body: some View {
        var footerView: some View {
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
            
            return HStack {
                toolsButton
                    .padding(10)
            }
        }
        
        var headerView: some View {
            var titleView: some View {
                Text(self.store.state.factionFilter.selectedFaction.rawValue)
                    .font(.title)
            }
            
            var favoritesFilterView: some View {
                Button(action: {
                    self.displayFavoritesOnly.toggle()
                    self.updateFavorites(showFavoritesOnly: self.displayFavoritesOnly)
                }) {
                    Image(systemName: self.displayFavoritesOnly ? "star.fill" :
                    "star")
                        .font(.title)
                        .foregroundColor(Color.yellow)
                }
            }
            
            var roundCount: some View {
                
                
                func increment() {
                    let newRound = store.state.faction.currentRound + 1
                    
                    setRound(newRound: newRound)
                }
                
                func decrement() {
                    var newRound = store.state.faction.currentRound - 1
                    
                    if newRound < 0 { newRound = 0 }
                    
                    setRound(newRound: newRound)
                }
                
                func reset() {
                    setRound(newRound: 0)
                }
                
                return HStack {
                    Button(action:{ increment() }) { Image(systemName: "plus.circle.fill").font(.largeTitle) }
                    
                    Text("Round: \(store.state.faction.currentRound)")
                        .font(.title)
                    
                    Button(action:{ decrement() }) { Image(systemName: "minus.circle.fill").font(.largeTitle) }
                    
                    Button(action:{ displayResetRoundCounter = true }) { Image(systemName: "xmark.octagon.fill").foregroundColor(.red).font(.title) }
                }.alert(isPresented: $displayResetRoundCounter) {
                    Alert(
                        title: Text("Reset"),
                        message: Text("Reset Round Counter?"),
                        primaryButton: Alert.Button.default(Text("Reset"), action: { reset() }),
                        secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
                    )
                }.onAppear(perform: {
                    self.loadRound()
                })
            }
            
            var squadCount: some View {
                Text("Squads: \(squadDataList.count)").font(.title)
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
            
            return HStack {
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
                squadCount
                Spacer()
                favoritesFilterView
                Spacer()
                roundCount
                Spacer()
                xwsImportButton
            }
        }
        
        var squadList: some View {
            var deleteAllAlertAction: () -> Void {
                get {
                    func old() {
                        _ = squadDataList.map { self.deleteSquad(squadData: $0)
                        }
                    }
                    
                    func new() {
                        deleteAllSquads()
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
            
            var emptySection: some View {
                Section {
                    Text("No squads found")
                }
            }
            
            var shipsSection: some View {
                return Section {
                    ForEach(squadDataList, id:\.self) { squadData in
                        Redux_FactionSquadCard(squadData: squadData,
                                               store: store,
                                               deleteCallback: self.deleteSquad,
                                               updateCallback: self.updateSquad)
                        .environmentObject(self.viewFactory)
                        .environmentObject(self.store)
                    }
                }
            }
            
            return List {
                if squadDataList.isEmpty {
                    emptySection
                } else {
                    shipsSection
                }
            }
            .padding(10)
            .onAppear {
                logMessage("Redux_FactionSquadList.squadList.onAppear()")
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
        
        return VStack {
            progressView
            
            headerView
                .padding(5)
            
            squadList
            
            footerView
        }
    }
    
    func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void {
        return {
            print("Cancelled \(title)")
            callback()
        }
    }
}

extension Redux_FactionSquadList {
    func pak() {
        func new() {
            self.viewModel.send(.deleteAllSquads)
        }

        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList) {
            new()
            return
        }
        
        self.store.send(.faction(action: .deleteAllSquads))

    }
        
    func deleteAllSquads() {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.deleteAllSquads)
        } else {
            self.store.send(.faction(action: .deleteAllSquads))
        }
    }
    
    func loadRound() {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.loadRound)
        }
        else {
            store.send(.faction(action: .loadRound))
        }
    }
    
    func setRound(newRound: Int) {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.setRound(newRound))
        }
        else {
            store.send(.faction(action: .setRound(newRound)))
        }
    }
    
    func deleteSquad(squadData: SquadData) {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.deleteSquad(squadData))
            refreshSquadsList()
        } else {
            self.store.send(.faction(action: .deleteSquad(squadData)))
            refreshSquadsList()
        }
    }

    func updateSquad(squadData: SquadData) {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.updateSquad(squadData))
        } else {
            self.store.send(.faction(action: .updateSquad(squadData)))
        }
    }

    func refreshSquadsList() {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.refreshSquadsList)
        } else {
            self.store.send(.faction(action: .loadSquads))
        }
    }

    func updateFavorites(showFavoritesOnly: Bool) {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.updateFavorites(showFavoritesOnly))
        } else {
            self.store.send(.faction(action: .updateFavorites(showFavoritesOnly)))
        }
    }
}

// MARK:- Redux_FactionSquadListViewModel
class Redux_FactionSquadListViewModel : ObservableObject {
    var store: MyAppStore
    var cancellables = Set<AnyCancellable>()
    @Published var viewProperties: Redux_FactionSquadListViewProperties
    
    init(store: MyAppStore) {
        self.store = store
        self.viewProperties = Redux_FactionSquadListViewProperties.none
        configureViewProperties()
    }
}

extension Redux_FactionSquadListViewModel {
    enum Redux_FactionSquadListViewModelAction {
        case deleteSquad(SquadData)
        case updateSquad(SquadData)
        case updateFavorites(Bool)
        case refreshSquadsList
        case deleteAllSquads
        case setRound(Int)
        case loadRound
    }
    
    func send(_ action: Redux_FactionSquadListViewModelAction) {
        switch(action) {
            case .refreshSquadsList:
                // Update viewProperties to instruct the view to
                // display a progress control
                displayProgressControl()
                self.store.send(.faction(action: .loadSquads))
                
            default :
                return
        }
    }
    
    func displayProgressControl() {
        let pendingViewProperties = Redux_FactionSquadListViewProperties(
            faction: self.viewProperties.faction,
            squadDataList: self.viewProperties.squadDataList,
            loadingState: .pending)
        
        self.viewProperties = pendingViewProperties
    }
}

extension Redux_FactionSquadListViewModel : ViewPropertyRepresentable {
    var viewPropertiesPublished: Published<Redux_FactionSquadListViewProperties> {
        self._viewProperties
    }
    
    var viewPropertiesPublisher: Published<Redux_FactionSquadListViewProperties>.Publisher {
        self.$viewProperties
    }
    
    func buildViewProperties(state: MyAppState) -> Redux_FactionSquadListViewProperties {
        return Redux_FactionSquadListViewProperties(
            faction: "",
            squadDataList: state.faction.squadDataList,
            loadingState: .loaded)
    }
}

// MARK:- Redux_FactionSquadListViewProperties
struct Redux_FactionSquadListViewProperties {
    enum ViewLoadingState {
        case idle
        case pending
        case loaded
    }
    
    let faction: String
    let squadDataList: [SquadData]
    let loadingState: ViewLoadingState
}

extension Redux_FactionSquadListViewProperties {
    static var none : Redux_FactionSquadListViewProperties {
        return Redux_FactionSquadListViewProperties(faction: "", squadDataList: [], loadingState: .idle)
    }
}

