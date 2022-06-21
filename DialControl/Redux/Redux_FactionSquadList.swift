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
    
    @State var displayFavoritesOnly: Bool = UserDefaults.standard.bool(forKey: "displayFavoritesOnly")
    @State var displayResetRoundCounter: Bool = false
    
    @DataBacked(key: "CoreDataTest", storage: CoreDataStorage()) var test: SquadData = SquadData.init()
    
    @DataBacked(key: "UserDefaultsTest", storage: CombineStorage(initialValue: 0)) var combineTest : Int = 0
    
    let faction: String
    
    // Dealloc tracker (strong ref)
    let printer: DeallocPrinter
    
    @StateObject var viewModel: Redux_FactionSquadListViewModel
    
    init(faction: String, store: MyAppStore) {
        self.store = store
        self.faction = faction
        self.printer = DeallocPrinter("Redux_FactionSquadList.init")
        let vm = Redux_FactionSquadListViewModel(store: store, viewID: self.printer.id)
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var progressView : some View {
        switch(self.viewModel.viewProperties.loadingState) {
            case .pending:
                return Text("Pending")
            case .idle:
                return Text("Idle")
            default:
                return Text("Squad Lists")
        }
    }
    
    var squadDataList : [SquadData] {
        get {
            let list = self.viewModel.viewProperties.squadDataList
//            let list = self.store.state.faction.squadDataList
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
                Text(version())
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
                    
                    Text("Round: \(viewModel.viewProperties.currentRound)")
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
    
    func loadRound() {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            
            self.viewModel.send(.loadRound)
            global_os_log("Redux_FactionSquadList.loadRound()")
        }
        else {
            store.send(.faction(action: .loadRound))
        }
    }
    
    func setRound(newRound: Int) {
        if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
        {
            self.viewModel.send(.setRound(newRound))
            global_os_log("Redux_FactionSquadList.setRound(newRound)", "newRound = \(newRound)")
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

// MARK:- Mock_Redux_FactionSquadListViewModel
class Mock_Redux_FactionSquadListViewModel : ObservableObject {
    let id = UUID()
    let viewID: UUID
    @Published var viewProperties: Redux_FactionSquadListViewProperties = Redux_FactionSquadListViewProperties.none
    
    init(store: MyAppStore, viewID: UUID)
    {
        self.viewID = viewID
        global_os_log("Mock_Redux_FactionSquadListViewModel.init \(id) for view :\(viewID)")
    }
    
    deinit {
        print("Mock_Redux_FactionSquadListViewModel.init \(id) for view :\(viewID)")
        global_os_log("Mock_Redux_FactionSquadListViewModel.init \(id) for view :\(viewID)")
    }
    
    func send(_ action: Redux_FactionSquadListViewModelAction) {
        switch(action) {
            default:
                print(action)
        }
    }
}

class Test_Redux_FactionSquadListViewModel : ObservableObject {
    let id = UUID()
    let viewID: UUID
    internal var cancellables = Set<AnyCancellable>()
    @Published var viewProperties: Redux_FactionSquadListViewProperties
    var store: MyAppStore
    
    init(store: MyAppStore, viewID: UUID) {
        self.store = store
        self.viewID = viewID
        self.viewProperties = Redux_FactionSquadListViewProperties.none
        configureViewProperties()
        global_os_log("allocated Test_Redux_FactionSquadListViewModel.init \(id) for view :\(viewID)")
    }
    
    func buildViewProperties(state: MyAppState) -> Redux_FactionSquadListViewProperties
    {
        let ret = Redux_FactionSquadListViewProperties(
            faction: "",
            squadDataList: state.faction.squadDataList,
            loadingState: .loaded,
            currentRound: self.viewProperties.currentRound)
        
        global_os_log("buildViewProperties") {
            return "\(ret.squadDataList.count) squads, loadingState: \(ret.loadingState)"
        }
        
        return ret
    }
    
    func configureViewProperties() {
        configureViewProperties_new()
    }
    
    func configureViewProperties_old() {
        let stateSink = store.statePublisher
            .lane("configureViewProperties() statePublisher")
            .os_log(message: "configureViewProperties() statePublisher")
            .map { state in
                self.buildViewProperties(state: state)
            }
            .print()
//            .removeDuplicates { (prev, current) -> Bool in
//                    // Considers points to be duplicate if the x coordinate
//                    // is equal, and ignores the y coordinate
//                prev.squadDataList == current.squadDataList
//            }
            //.lane("configureViewProperties() buildViewProperties")
            .os_log(message: "configureViewProperties() buildViewProperties")
            .sink { [weak self] viewProperties in
                self?.viewProperties = viewProperties
            }
        
        self.cancellables.insert(AnyCancellable(stateSink))
        
        global_os_log("Test_Redux_FactionSquadListViewModel.configureViewProperties() \(id) \(self.cancellables.count) subscriptions")
    }

    func configureViewProperties_new() {
        store.statePublisher
            .lane("configureViewProperties() statePublisher")
            .os_log(message: "configureViewProperties() statePublisher")
            .map { state in
                self.buildViewProperties(state: state)
            }
            .print()
            .removeDuplicates { (prev, current) -> Bool in
                    // Considers points to be duplicate if the x coordinate
                    // is equal, and ignores the y coordinate
                prev.squadDataList == current.squadDataList
            }
            //.lane("configureViewProperties() buildViewProperties")
            .os_log(message: "configureViewProperties() buildViewProperties")
            .assign(to: &$viewProperties)
        
        global_os_log("Test_Redux_FactionSquadListViewModel.configureViewProperties() \(id) \(self.cancellables.count) subscriptions")
    }
    
    deinit {
        global_os_log("deallocated Test_Redux_FactionSquadListViewModel.deinit \(id)  for view :\(viewID)")
    }
}
// MARK:- Redux_FactionSquadListViewModel
class Redux_FactionSquadListViewModel : ObservableObject {
    let id = UUID()
    var store: MyAppStore
    var cancellable: AnyCancellable?
    @Published var viewProperties: Redux_FactionSquadListViewProperties
    
    init(store: MyAppStore, viewID: UUID)
    {
        self.store = store
        self.viewProperties = Redux_FactionSquadListViewProperties.none
        configureViewProperties()
        global_os_log("allocated Redux_FactionSquadListViewModel.init \(id) for view :\(viewID)")
//        cancellable?.cancel()
    }
    
    deinit {
//        cancellable?.cancel()
        global_os_log("deallocated Redux_FactionSquadListViewModel.deinit \(id)  for view :\(id)")
    }
    
    func configureViewProperties() {
        let stateSink = store.statePublisher
        .lane("configureViewProperties() statePublisher")
        .map { [weak self] state in
            self?.buildViewProperties(state: state) ?? Redux_FactionSquadListViewProperties.none
        }
        .print()
        .removeDuplicates { (prev, current) -> Bool in
            let squadDuplicate = (prev.squadDataList == current.squadDataList)
            let currentRoundDuplicate = (prev.currentRound == current.currentRound)
            return squadDuplicate && currentRoundDuplicate
        }
        .handleEvents(receiveSubscription: { [weak self] sub in
            guard let self = self else { return }
            global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(self.id) subscribed")
        },
        receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(self.id) completion")
        },
        receiveCancel: { [weak self] in
            global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(String(describing: self?.id)) cancel")
            guard let self = self else { return }
            
            global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(String(describing: self.id)) cancel")
        })
        .sink(receiveCompletion: { [weak self] value in
            guard let self = self else { return }
            switch(value) {
                case .finished:
                    global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(self.id) finished")
                case .failure:
                    global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(self.id) failure")
            }
        }, receiveValue: { [weak self] viewProperties in
            guard let self = self else { return }
            global_os_log("Redux_FactionSquadListViewModel.configureViewProperties()", "\(self.viewProperties)")
            self.viewProperties = viewProperties
        })
        
        self.cancellable = AnyCancellable(stateSink)
        
        global_os_log("Redux_FactionSquadListViewModel.configureViewProperties() \(id) 1 subscriptions")
    }
}

enum Redux_FactionSquadListViewModelAction {
    case deleteSquad(SquadData)
    case updateSquad(SquadData)
    case updateFavorites(Bool)
    case refreshSquadsList
    case deleteAllSquads
    case setRound(Int)
    case loadRound
}

extension Redux_FactionSquadListViewModel {
    func send(_ action: Redux_FactionSquadListViewModelAction) {
        switch(action) {
            case .refreshSquadsList:
                // Update viewProperties to instruct the view to
                // display a progress control
//                displayProgressControl()
                self.store.send(.faction(action: .loadSquads))
            
            case let .deleteSquad(squadData):
                self.store.send(.faction(action: .deleteSquad(squadData)))
            
            case let .updateSquad(squadData):
                self.store.send(.faction(action: .updateSquad(squadData)))
                
            case let .updateFavorites(showFavoritesOnly):
                self.store.send(.faction(action: .updateFavorites(showFavoritesOnly)))
            
            case .deleteAllSquads:
                self.store.send(.faction(action: .deleteAllSquads))
                
            case let .setRound(newRound):
                store.send(.faction(action: .setRound(newRound)))
                
            case .loadRound:
                store.send(.faction(action: .loadRound))
        }
    }
    
    func displayProgressControl() {
        let pendingViewProperties = Redux_FactionSquadListViewProperties(
            faction: self.viewProperties.faction,
            squadDataList: self.viewProperties.squadDataList,
            loadingState: .pending(0.1),
            currentRound: self.viewProperties.currentRound)
        
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
    
    func buildViewProperties(state: MyAppState) -> Redux_FactionSquadListViewProperties
    {
        let ret = Redux_FactionSquadListViewProperties(
            faction: "",
            squadDataList: state.faction.squadDataList,
            loadingState: .loaded,
            currentRound: state.faction.currentRound)
        
        global_os_log("buildViewProperties") {
            return ret.description
        }
        
        return ret
    }
}

// MARK:- Redux_FactionSquadListViewProperties
struct Redux_FactionSquadListViewProperties {
    enum ViewLoadingState {
        case idle
        case pending(Double)
        case loaded
    }
    
    let faction: String
    let squadDataList: [SquadData]
    let loadingState: ViewLoadingState
    let currentRound: Int
}

extension Redux_FactionSquadListViewProperties: CustomStringConvertible {
    var description: String {
        "faction: \(faction) loadingState: \(loadingState) currentRound: \(currentRound) squadDataList: \(squadDataList)"
    }
}

extension Redux_FactionSquadListViewProperties {
    static var none : Redux_FactionSquadListViewProperties {
        return Redux_FactionSquadListViewProperties(
            faction: "",
            squadDataList: [],
            loadingState: .idle,
            currentRound: 0)
    }
}

