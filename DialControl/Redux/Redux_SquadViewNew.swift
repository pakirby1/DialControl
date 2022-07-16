////
////  Redux_SquadView.swift
////  DialControl
////
////  Created by Phil Kirby on 3/22/20.
////  Copyright © 2020 SoftDesk. All rights reserved.
////
//
import Foundation
import SwiftUI
import Combine
import TimelaneCombine

//MARK:- View
struct Redux_SquadViewNew: View, DamagedSquadRepresenting {
    @EnvironmentObject var viewFactory: ViewFactory
    
    @State var activationOrder: Bool = true
    @State private var displayResetAllConfirmation: Bool = false
    @State var isFirstPlayer: Bool = false
    @State var victoryPoints: Int32 = 0
    
    @State private var firstPlayerRefresh: Bool = false
    @State var shipPilotsNew : [ShipPilot] = []
    
    let theme: Theme = WestworldUITheme()
    let squad: Squad
    let squadData: SquadData
    @StateObject var viewModel: Redux_SquadViewNewViewModel
    
    init(store: MyAppStore, squad: Squad, squadData: SquadData) {
        self.squad = squad
        self.squadData = squadData
        self._viewModel = StateObject(wrappedValue: Redux_SquadViewNewViewModel(store: store))
    }
    
    var shipPilots: [ShipPilot] {
        print("PAKshipPilots \(Date()) count: \(self.viewModel.viewProperties.shipPilots.count)")
        self.shipPilotsNew.forEach{ print("PAKshipPilots \(Date()) \($0.shipName)") }

        return self.shipPilotsNew
    }
    
    var chunkedShips : Array<[ShipPilot]> {
        return sortedShipPilots.chunked(into: 2)
    }
    
    var sortedShipPilots: [ShipPilot] {
        // TODO: Switch & AppStore
        
        var copy = self.shipPilotsNew
        
        if (activationOrder) {
            copy.sort(by: { $0.ship.pilots[0].initiative < $1.ship.pilots[0].initiative })
        } else {
            copy.sort(by: { $0.ship.pilots[0].initiative > $1.ship.pilots[0].initiative })
        }
        
        return copy
    }
}

extension Redux_SquadViewNew {
    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    private var shipsView: AnyView {
        return shipsGrid.eraseToAnyView()
    }
    
    var shipsListSection: some View {
        Section {
            ForEach(sortedShipPilots) { shipPilot in
                self.buildShipButton(shipPilot: shipPilot)
            }
        }
    }
    
    var shipsGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(chunkedShips, id: \.self) { index in
                HStack {
                    ForEach(index, id:\.self) { shipPilot in
                        self.buildShipButton(shipPilot: shipPilot)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    var header: some View {
        HStack {
            BackButtonView()
                .environmentObject(viewFactory)
           
            Spacer()
            ObjectiveScoreView(currentPoints: self.$victoryPoints,
                               action: {
                                    print("victory points = \($0)")
                                setVictoryPoints(points: $0)
                               })
                .environmentObject(viewFactory)
            
            Spacer()
            
            CustomToggleView(label: "First Player", binding: $isFirstPlayer)
        }
        .padding(10)
        .onChange(of: isFirstPlayer, perform: {
            // Hack because swift thinks I don't want to perform
            // an assignment (=) vs. a boolean check (==)
            let x = $0
            self.squadData.firstPlayer = x
            self.updateSquad(squadData: self.squadData)
            
            if (FeaturesManager.shared.isFeatureEnabled(.firstPlayerUpdate)) {
                // for each pilot update system phase state
                disableSystemPhaseForAllPilots()
                hideAllDials()
                self.firstPlayerRefresh.toggle()
            }
        })
    }

    private func hideAllDials() {
        updateAllPilots() { $0.dial_status = .hidden }
    }
    
    private func disableSystemPhaseForAllPilots() {
        
        func setSystemPhaseState_Old(shipPilot: ShipPilot, state: Bool) {
//            measure(name: "setSystemPhaseState(state:\(state)") {
                if let data = shipPilot.pilotStateData {
                    let name = shipPilot.pilotName
                    data.change(update: { psd in
                        
                        print("Redux_PilotCardView.setSystemPhaseState name: \(name) state: \(state)")

                        psd.hasSystemPhaseAction = state
                        self.viewModel.store.send(.squad(action: .updatePilotState(psd, shipPilot.pilotState)))

                        print("Redux_PilotCardView $0.hasSystemPhaseAction = \(String(describing: psd.hasSystemPhaseAction))")
                    })
                }
//            }
        }
        
        sortedShipPilots.forEach{ shipPilot in
            setSystemPhaseState_Old(shipPilot: shipPilot, state: false)
        }
        
        getShips()
        
//        updateAllPilots() { $0.updateSystemPhaseAction(value: false) }
    }
    
    private func setSystemPhaseForAllPilots(value: Bool) {
        updateAllPilots() { $0.updateSystemPhaseState(value: value) }
    }
    
    private func updateAllPilots(_ handler: (inout PilotStateData) -> ()) {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                handler(&data)
                
                // Update the store
                self.updatePilotState(pilotStateData: data,
                                      pilotState: shipPilot.pilotState)
            }
        }
    }
    
    var content: some View {
        let points = Text("\(squad.points ?? 0)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
        
        let engage = Button(action: {
            self.processEngage()
        }) {
            Text(self.activationOrder ? "Engage" : "Activate").foregroundColor(Color.white)
        }
        
        let title = Text(squad.name ?? "Unnamed")
            .font(.title)
            .lineLimit(1)
            .foregroundColor(theme.TEXT_FOREGROUND)
        
        let reset = Button(action: {
            self.displayResetAllConfirmation = true
        }) {
            Text("Reset All")
                .font(.title)
                .foregroundColor(Color.red)
        }.alert(isPresented: $displayResetAllConfirmation) {
            Alert(
                title: Text("Reset All"),
                message: Text("Reset All Pilots"),
                primaryButton: Alert.Button.default(Text("Reset"), action: { self.resetAllShips() }),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
            )
        }
        
        let damaged = Text("\(damagedPoints)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.red)
            .clipShape(Circle())
        
        var firstPlayer: some View {
            if isFirstPlayer == true {
                return AnyView(firstPlayerSymbol)
            }
            
            return AnyView(EmptyView())
        }
        
        var dialState: some View {
            func row(label: String, text: String) -> some View {
                return Text("\(label): \(text)")
            }
            
            return VStack {
                row(label: "dialsState", text: self.viewModel.viewProperties.dialsState.description)
                row(label: "revealedDialCount", text: self.viewModel.viewProperties.revealedDialCount.description)
                row(label: "hiddenDialCount", text: self.viewModel.viewProperties.hiddenDialCount.description)
                row(label: "shipPilots Count", text: self.viewModel.viewProperties.shipPilots.count.description)
            }
        }
        
        var hideOrRevealAll: some View {
            func buildButton(_ newDialStatus: DialStatus) -> some View {
                global_os_log("Redux_SquadViewNew.hideOrRevealAll.buildButton newDialStatus: \(newDialStatus)")
                let title: String = (newDialStatus == .hidden) ? "Hide" : "Reveal"
                global_os_log("Redux_SquadViewNew.hideOrRevealAll.buildButton title: \(title)")
                
                return Button(action: {
                    func logDetails() {
                        global_os_log("Redux_SquadViewNew.hideOrRevealAll.buildButton dialsState: \(self.viewModel.viewProperties.dialsState)")
                        global_os_log("Redux_SquadViewNew.hideOrRevealAll.buildButton revealedDialCount: \(self.viewModel.viewProperties.revealedDialCount)")
                        global_os_log("Redux_SquadViewNew.hideOrRevealAll.buildButton shipPilots Count: \(self.viewModel.viewProperties.shipPilots.count)")
                    }
                    
                    logDetails()
                    self.updateAllDials(newDialStatus: newDialStatus)
                }) {
                    Text(title).foregroundColor(Color.white)
                }
            }
            
            return (self.viewModel.viewProperties.dialsState == .hidden) ? buildButton(.revealed) : buildButton(.hidden)
        }
    
        return ZStack {
            VStack(alignment: .leading) {
                // Header
                HStack {
                    points

                    Spacer()

                    engage

                    Spacer()

                    title

                    firstPlayer

                    Spacer()

                    hideOrRevealAll

                    Spacer()

                    damaged
                }.padding(20)

//                HStack {
//                    Spacer()
//                    dialState
//                    Spacer()
//                }
                
                // Body
                if shipPilots.isEmpty {
                    emptySection
                } else {
                    ShipGridView(shipPilots: self.shipPilotsNew,
                                 updatePilotState: self.updatePilotState(pilotStateData:pilotState:),
                                 activationOrder: self.activationOrder,
                                 buildShipButtonCallback: self.buildShipButton(shipPilot:))
//                    shipsView
                }
                
                Text("\(self.viewModel.viewProperties.shipPilots.count)")
                
                // Footer
                CustomDivider()
                HStack {
                    Spacer()
                    reset
                    Spacer()
                }
            }
            .multilineTextAlignment(.center)
        }
        .onAppear{
            print("PAK_DialStatus SquadCardView.onAppear()")
            executionTime("Perf Redux_SquadView.content.onAppear()") {
                self.viewModel.loadShips(squad: squad, squadData: squadData)
                self.activationOrder = self.squadData.engaged
                print("PAKshipPilots \(Date()) .onAppear")
            }
        }
        .onReceive(self.viewModel.$viewProperties) {
            let shipPilots = $0.shipPilots
            self.shipPilotsNew = $0.shipPilots
            global_os_log("FeatureId.firstPlayerUpdate","Redux_SquadViewNew.content.onReceive \(shipPilots)")
        }
//        .onChange(of: self.shipPilotsNew) {
//            global_os_log("FeatureId.firstPlayerUpdate","Redux_SquadViewNew.content.onChange(of: shipPilotsNew) \($0.count)")
//        }
    }
    
    var body: some View {
        func onAppearBlock() {
            self.isFirstPlayer = self.squadData.firstPlayer
            self.victoryPoints = self.squadData.victoryPoints
        }
        
        return VStack {
            if (self.firstPlayerRefresh) {
                Text("First Player Refreshed")
            }
            
            header
            content
            
        }
        .onAppear() {
            executionTime("Redux_SquadView.body.onAppear()") {
                onAppearBlock()
            }
        }
        .onChange(of: self.firstPlayerRefresh) {
            global_os_log("FeatureId.firstPlayerUpdate","firstPlayerRefresh= \($0.description)")
        }
    }
    
    func getShips() {
        global_os_log("FeatureId.firstPlayerUpdate","Redux_SquadViewNew.getShips()")
        self.viewModel.loadShips(squad: self.squad, squadData: self.squadData)
//        self.viewModel.store.send(.squad(action: .getShips(self.squad, self.squadData)))
    }
    
    private func buildShipButton(shipPilot: ShipPilot) -> some View {
        func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
            // Get the dial status from the pilot state
            if let data = shipPilot.pilotStateData {
                print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
                                                   dialStatus: data.dial_status,
                                                   updatePilotStateCallback: self.updatePilotState,
                                                   getShips: getShips,
                                                   hasSystemPhaseAction: shipPilot.pilotStateData?.hasSystemPhaseAction ?? false)
                    .environmentObject(self.viewFactory)
                                .environmentObject(self.viewModel.store))
            }
            
            return AnyView(EmptyView())
        }
        
        return Button(action: {
            self.viewFactory.viewType = .shipViewNew(shipPilot, self.squad)
        }) {
            buildPilotCardView(shipPilot: shipPilot)
        }
    }
    
    struct ObjectiveScoreView : View {
        @Binding var currentPoints: Int32
        let action: (Int32) -> Void
        let size = CGSize(width: 40, height: 40 * 1.55)
        @State var resetPoints: Bool = false
        
        init(currentPoints: Binding<Int32>, action: @escaping (Int32) -> Void) {
            _currentPoints = currentPoints
            self.action = action
        }
        
        var body: some View {
            HStack {
                VectorImageButton(imageName: "VictoryYellow", size: size) {
                    currentPoints += 1
                    action(currentPoints)
                    /*
                    var currentPoints = self.squadData.victoryPoints
                    currentPoints += 1
                    self.squadData.victoryPoints = currentPoints
                    self.updateSquad(squadData: self.squadData)
                    */
                }
                
                IndicatorView(label: "\(self.currentPoints)",
                    bgColor: Color.green,
                    fgColor: Color.white)
                
                VectorImageButton(imageName: "VictoryRed2", size: size) {
                    currentPoints -= 1
                    let newPoints = (currentPoints < 0 ? 0 : currentPoints)
                    currentPoints = newPoints
                    action(newPoints)
                    /*
                    var currentPoints = self.squadData.victoryPoints
                    currentPoints -= 1
                     
                    self.squadData.victoryPoints = (currentPoints < 0 ? 0 : currentPoints)
                     
                    self.updateSquad(squadData: self.squadData)
                    */
                }
                
                CustomToggleView(label: "Reset Points", binding: $resetPoints)
            }
            .onChange(of: resetPoints, perform: { _ in
                currentPoints = 0
                action(currentPoints)
            })
        }
    }
}

//MARK:- Behavior
extension Redux_SquadViewNew {
    func setVictoryPoints(points: Int32) {
        // Mutate & Persist
        self.squadData.victoryPoints = Int32(points)
        self.updateSquad(squadData: self.squadData)
        
        // Update the local @State
        self.victoryPoints = points
    }
    
    func setFirstPlayer(_ isFirstPlayer: Bool) {
        // Mutate & Persist
        self.squadData.firstPlayer = isFirstPlayer
        self.updateSquad(squadData: self.squadData)
        
        // Update the local @State
        self.isFirstPlayer = isFirstPlayer
    }
    
    func updateSquad(squadData: SquadData) {
        self.viewModel.updateSquad(squadData: squadData)
    }
    
    func updatePilotState(pilotStateData: PilotStateData,
                                  pilotState: PilotState)
    {
        self.viewModel.updatePilotState(pilotStateData: pilotStateData, pilotState: pilotState)
    }
    
    private func processEngage() {
        self.activationOrder.toggle()
        self.squadData.engaged = self.activationOrder
        self.updateSquad(squadData: self.squadData)
    }
    
    // TODO: Switch & AppStore
    
    
    private func resetAllShips() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                data.change(update: {
                    $0.reset()
                    
                    self.updatePilotState(pilotStateData: $0,
                                          pilotState: shipPilot.pilotState)
                })
            }
        }
        
        setVictoryPoints(points: 0)
        setFirstPlayer(false)
        self.viewModel.loadShips(squad: self.squad, squadData: self.squadData)
    }
    
    private func updateAllDials() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                if data.dial_status != .destroyed {
                    data.change(update: {
                        print("PAK_DialStatus pilotStateData.id: \($0)")
                        let revealAllDialsStatus: DialStatus = (self.viewModel.viewProperties.dialsState == .revealed) ? .revealed : .hidden
                        $0.dial_status = revealAllDialsStatus
                        
                        self.updatePilotState(pilotStateData: $0,
                                                           pilotState: shipPilot.pilotState)
                        print("PAK_DialStatus updateAllDials $0.dial_status = \(revealAllDialsStatus)")
                        print("PAK_DialStatus updateAllDials $0.dial_revealed = \($0.dial_status)")
                    })
                }
            }
        }
    }
    
    private func updateAllDials(newDialStatus: DialStatus) {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                if data.dial_status != .destroyed {
                    data.change(update: {
                        print("PAK_DialStatus pilotStateData.id: \($0)")
    
                        $0.dial_status = newDialStatus
                        
                        self.updatePilotState(pilotStateData: $0,
                                                           pilotState: shipPilot.pilotState)
                        print("PAK_DialStatus updateAllDials $0.dial_status = \($0.dial_status)")
                    })
                }
            }
        }
    }
}

//MARK:- View Model
class Redux_SquadViewNewViewModel : ObservableObject {
    var store: MyAppStore
    @Published var viewProperties: Redux_SquadViewNewViewProperties
    var cancellable: AnyCancellable?
    
    init(store: MyAppStore) {
        self.store = store
        self.viewProperties = Redux_SquadViewNewViewProperties.none
        configureViewProperties()
    }
}

extension Redux_SquadViewNewViewModel {
    func loadShips(squad: Squad, squadData: SquadData) {
        // Make request to store to build the store.shipPilots
        
        logMessage("damagedPoints SquadCardView.loadShips")
        print("PAK_DialStatus SquadCardView.loadShips()")
        self.store.send(.squad(action: .getShips(squad, squadData)))
    }
    
    func updateSquad(squadData: SquadData) {
        self.store.send(.squad(action: .updateSquad(squadData)))
    }
    
    func updatePilotState(pilotStateData: PilotStateData,
                                  pilotState: PilotState)
    {
        self.store.send(.squad(action: .updatePilotState(pilotStateData, pilotState)))
    }
}

extension Redux_SquadViewNewViewModel : ViewPropertyRepresentable {
    func configureViewProperties() {
        let stateSink = self
            .store
            .statePublisher
            .sink{ [weak self] state in
                guard let self = self else { return }
                self.viewProperties = self.buildViewProperties(state: state)
                let systemPhaseStates: [(String, Bool)] = state.squad.shipPilots.map {
                    if let x = $0.pilotStateData?.hasSystemPhaseAction {
                        return ($0.pilotName, x)
                    }
                    
                    return ($0.pilotName, false)
                }
                
                let descriptions : [String] = systemPhaseStates.map { $0.0 + " value:" + $0.1.description }
                
                let y = descriptions.joined(separator: "\n")
                
                global_os_log("FeatureId.firstPlayerUpdate", "Redux_SquadViewNewViewModel.configureViewProperties():\n" + y)
            }
        
        self.cancellable = AnyCancellable(stateSink)
    }
    
    var viewPropertiesPublished: Published<Redux_SquadViewNewViewProperties> {
        self._viewProperties
    }
    
    var viewPropertiesPublisher: Published<Redux_SquadViewNewViewProperties>.Publisher {
        self.$viewProperties
    }
    
    func buildViewProperties(state: MyAppState) -> Redux_SquadViewNewViewProperties
    {
        return Redux_SquadViewNewViewProperties(shipPilots: state.squad.shipPilots)
    }
}

//MARK:- View Properties
struct Redux_SquadViewNewViewProperties {
    let shipPilots: [ShipPilot]
}

extension Redux_SquadViewNewViewProperties {
    static var none : Redux_SquadViewNewViewProperties {
        return Redux_SquadViewNewViewProperties(
            shipPilots: [])
    }
    
    var revealedDialCount: Int {
        self.shipPilots.filter{
            guard let status = $0.pilotStateData?.dial_status else { return false }
            return (status == .revealed) || (status == .destroyed)
        }.count
    }
    
    var hiddenDialCount: Int {
        self.shipPilots.count - self.revealedDialCount
    }
    
    var dialsState : SquadDialsState {
        get {
            global_os_log("Redux_SquadViewNewViewProperties dialsState: revealedDialCount: \(self.revealedDialCount) shipPilots.count: \(self.shipPilots.count)")
            
            if self.revealedDialCount == self.shipPilots.count {
                global_os_log("Redux_SquadViewNewViewProperties dialsState: counts match .revealed")
                return .revealed
            } else {
                global_os_log("Redux_SquadViewNewViewProperties dialsState: counts do not match .hidden")
                return .hidden
            }
        }
    }
}

extension Redux_SquadViewNewViewProperties: CustomStringConvertible {
    var description: String {
        "shipPilots \(self.shipPilots.count)"
    }
}

enum SquadDialsState: CustomStringConvertible {
    case revealed
    case hidden
    
    var description: String {
        switch(self) {
            case .hidden: return "Hidden"
            case .revealed: return "Revealed"
        }
    }
}

struct ShipGridView<ShipButton: View> : View {
    let shipPilots: [ShipPilot]
    let updatePilotState: (PilotStateData, PilotState) -> ()
    let activationOrder: Bool
    let buildShipButtonCallback: (ShipPilot) -> ShipButton
    
    var chunkedShips : [[ShipPilot]] {
        return sortedShipPilots.chunked(into: 2)
    }
    
    var sortedShipPilots: [ShipPilot] {
        // TODO: Switch & AppStore
        
        var copy = self.shipPilots
        
        if (activationOrder) {
            copy.sort(by: { $0.ship.pilots[0].initiative < $1.ship.pilots[0].initiative })
        } else {
            copy.sort(by: { $0.ship.pilots[0].initiative > $1.ship.pilots[0].initiative })
        }
        
        return copy
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(chunkedShips, id: \.self) { index in
                HStack {
                    ForEach(index, id:\.self) { shipPilot in
                        self.buildShipButton(shipPilot: shipPilot)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    func buildShipButton(shipPilot: ShipPilot) -> some View {
        return buildShipButtonCallback(shipPilot)
    }
}
