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
    @State var shipPilotsNew : [ShipPilot] = []
    @State private var displayWonLostCount: Bool = false
    
    @State private var viewProperties: Redux_SquadViewNewViewPropertiesNew?
    
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
    
    var wonLostCountButton: some View {
        Button(action: {
            self.displayWonLostCount = true
        }) {
            let wonCount: String = self.viewModel.viewProperties.wonCount.description
            let lostCount: String = self.viewModel.viewProperties.lostCount.description
            
            Text("Won: \(wonCount) Lost: \(lostCount)")
                .font(.title)
                .foregroundColor(Color.red)
        }
    }
}

extension Redux_SquadViewNew {
    var imageOverlayView: AnyView {
        var wonLossCountOverlay: some View {
            ZStack {
                Color
                    .gray
                    .opacity(0.5)
                    .onTapGesture{
                        self.displayWonLostCount = false
                    }
                
                HStack {
                    Spacer()
                    PillButton(label: "Won: \(self.viewModel.viewProperties.wonCount)",
                               add: {
//                                self.squadData.wonCount += self.squadData.wonCount
//                                self.viewModel.updateSquad(squadData: T##SquadData)
                               },
                               subtract: {},
                               reset: {})
                    
                    PillButton(label: "Lost: \(self.viewModel.viewProperties.lostCount)",
                               add: {},
                               subtract: {},
                               reset: {})
                    Spacer()
                }
            }
        }
        
        let defaultView = AnyView(Color.clear)
        
        print("Redux_SquadViewNew var displayWonLostCount self.displayWonLostCount=\(self.displayWonLostCount)")

        if (self.displayWonLostCount == true) {
            return AnyView(wonLossCountOverlay)
        } else {
            return defaultView
        }
    }
    
    var emptySection: some View {
        Section {
            Text("No ships found")
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
            wonLostCountButton
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
            }
        })
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
        
        let totalHealth = IndicatorView(label: "30", bgColor: .white, fgColor: .black)
        
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
    
        var header: some View {
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

                totalHealth
            }.padding(20)
        }
        
        var footer: some View {
            HStack {
                Spacer()
                reset
                Spacer()
            }
        }
        
        return ZStack {
            VStack(alignment: .leading) {
                // Header
                header
                
                // Body
                if shipPilots.isEmpty {
                    emptySection
                } else {
                    ShipGridView(shipPilots: self.shipPilotsNew,
                                 activationOrder: self.activationOrder,
                                 onPilotTapped: self.pilotTapped,
                                 getShips: self.getShips)
                        .environmentObject(viewModel.store)
                        .environment(\.updatePilotStateHandler, updatePilotState)
                }
                
                CustomDivider()
                footer
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
    }
    
    func body(viewModel: Redux_SquadViewNewViewModel) -> some View {
        return bodyView
    }
    
    var bodyView: some View {
        func onAppearBlock() {
            self.isFirstPlayer = self.squadData.firstPlayer
            self.victoryPoints = self.squadData.victoryPoints
        }
        
        return VStack {
            header
            content
        }
        .overlay(imageOverlayView)
        .onAppear() {
            executionTime("Redux_SquadView.body.onAppear()") {
                onAppearBlock()
            }
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
                }
                
                IndicatorView(label: "\(self.currentPoints)",
                    bgColor: Color.green,
                    fgColor: Color.white)
                
                VectorImageButton(imageName: "VictoryRed2", size: size) {
                    currentPoints -= 1
                    let newPoints = (currentPoints < 0 ? 0 : currentPoints)
                    currentPoints = newPoints
                    action(newPoints)
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
    private func hideAllDials() {
        updateAllPilots() { $0.dial_status = .hidden }
    }
    
    private func disableSystemPhaseForAllPilots() {
        func setSystemPhaseState_Old(shipPilot: ShipPilot, state: Bool) {
            if let data = shipPilot.pilotStateData {
                let name = shipPilot.pilotName
                data.change(update: { psd in
                    
                    print("Redux_PilotCardView.setSystemPhaseState name: \(name) state: \(state)")
                    
                    psd.hasSystemPhaseAction = state
                    self.viewModel.store.send(.squad(action: .updatePilotState(psd, shipPilot.pilotState)))
                    
                    print("Redux_PilotCardView $0.hasSystemPhaseAction = \(String(describing: psd.hasSystemPhaseAction))")
                })
            }
        }
        
        viewModel.viewProperties.sortedShipPilots.forEach{ shipPilot in
            setSystemPhaseState_Old(shipPilot: shipPilot, state: false)
        }
        
        getShips()
    }
    
    private func updateAllPilots(_ handler: (inout PilotStateData) -> ()) {
        viewModel.viewProperties.sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                handler(&data)
                
                // Update the store
                self.updatePilotState(pilotStateData: data,
                                      pilotState: shipPilot.pilotState)
            }
        }
    }
    
    func getShips() {
        global_os_log("FeatureId.firstPlayerUpdate","Redux_SquadViewNew.getShips()")
        self.viewModel.loadShips(squad: self.squad, squadData: self.squadData)
    }
    
    func pilotTapped(shipPilot: ShipPilot) {
        self.viewFactory.viewType = .shipViewNew(shipPilot, self.squad)
    }
    
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
    
    func flipDial(pilotStateData: PilotStateData, pilotState: PilotState) {
        self.viewModel.flipDial(pilotStateData: pilotStateData, pilotState: pilotState)
    }
    
    private func processEngage() {
        self.activationOrder.toggle()
        self.squadData.engaged = self.activationOrder
        self.updateSquad(squadData: self.squadData)
    }
    
    private func resetAllShips() {
        viewModel.viewProperties.sortedShipPilots.forEach{ shipPilot in
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
        viewModel.viewProperties.sortedShipPilots.forEach{ shipPilot in
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
        viewModel.viewProperties.sortedShipPilots.forEach{ shipPilot in
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

extension Redux_SquadViewNew : ViewModelRepresentable {
    func buildViewModel(store: MyAppStore) -> Redux_SquadViewNewViewModel {
        global_os_log("Redux_SquadViewNew") { "buildViewModel(store:)" }
        return Redux_SquadViewNewViewModel(store: store)
    }
 
    func buildView(viewModel: Redux_SquadViewNewViewModel) -> some View {
        global_os_log("CountViewContainerHelper") { "body(viewModel:)" }
        self.viewProperties = viewModel.buildViewProperties()
        let v = self.bodyView
        return v
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
    
    func flipDial(pilotStateData: PilotStateData,
                  pilotState: PilotState)
    {
        self.store.send(.squad(action: .flipDial(pilotStateData, pilotState)))
    }
}

extension Redux_SquadViewNewViewModel : ViewPropertyRepresentable {
    func configureViewProperties() {
        let stateSink = self
            .store
            .statePublisher
            .sink{ [weak self] state in
                guard let self = self else { return }
                self.bind(state: state)
            }
        
        self.cancellable = AnyCancellable(stateSink)
    }
    
    func bind(state: MyAppState) {
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
    
    var viewPropertiesPublished: Published<Redux_SquadViewNewViewProperties> {
        self._viewProperties
    }
    
    var viewPropertiesPublisher: Published<Redux_SquadViewNewViewProperties>.Publisher {
        self.$viewProperties
    }
    
    func buildViewProperties(state: MyAppState) -> Redux_SquadViewNewViewProperties
    {
        return Redux_SquadViewNewViewProperties(shipPilots: state.squad.shipPilots,
                                                wonCount: state.squad.wonCount,
                                                lostCount: state.squad.lostCount)
    }
    
    func buildViewProperties() -> Redux_SquadViewNewViewPropertiesNew {
        return Redux_SquadViewNewViewPropertiesNew(store: store,
                                                   shipPilots: store.state.squad.shipPilots,
                                                wonCount: store.state.squad.wonCount,
                                                lostCount: store.state.squad.lostCount)
    }
}

//MARK:- View Properties
struct Redux_SquadViewNewViewProperties {
    let shipPilots: [ShipPilot]
    var activationOrder: Bool = false
    let wonCount: Count
    let lostCount: Count
}

extension Redux_SquadViewNewViewProperties {
    var sortedShipPilots: [ShipPilot] {
        var copy = self.shipPilots

        if (activationOrder) {
            copy.sort(by: { $0.ship.pilots[0].initiative < $1.ship.pilots[0].initiative })
        } else {
            copy.sort(by: { $0.ship.pilots[0].initiative > $1.ship.pilots[0].initiative })
        }

        return copy
    }
    
    var chunkedShips : Array<[ShipPilot]> {
        return sortedShipPilots.chunked(into: 2)
    }
    
    static var none : Redux_SquadViewNewViewProperties {
        return Redux_SquadViewNewViewProperties(
            shipPilots: [],
            wonCount: Count.zero, lostCount: Count.zero)
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

struct Redux_SquadViewNewViewPropertiesNew {
    var store: MyAppStore
    let shipPilots: [ShipPilot]
    var activationOrder: Bool = false
    let wonCount: Count
    let lostCount: Count
}

extension Redux_SquadViewNewViewPropertiesNew {
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
    
    func flipDial(pilotStateData: PilotStateData,
                  pilotState: PilotState)
    {
        self.store.send(.squad(action: .flipDial(pilotStateData, pilotState)))
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

struct ShipGridView : View {
    let shipPilots: [ShipPilot]
    let activationOrder: Bool
    let onPilotTapped: (ShipPilot) -> ()
    let getShips: () -> ()
    @EnvironmentObject var store: MyAppStore
    @Environment(\.updatePilotStateHandler) var updatePilotState
    
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
                        self.buildShipButton(shipPilot: shipPilot, getShipsHandler: getShips)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    struct ShipButton: View {
        @EnvironmentObject var store: MyAppStore
        @Environment(\.updatePilotStateHandler) var updatePilotState
        let shipPilot: ShipPilot
        let getShips: () -> ()
        
        var body: some View {
            if let data = shipPilot.pilotStateData {
                print("PAK_ShipButton \(shipPilot.pilotName) shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
                                                   dialStatus: data.dial_status,
                                                   hasSystemPhaseAction: shipPilot.pilotStateData?.hasSystemPhaseAction ?? false)
                                .environmentObject(SquadViewHandler(store: store, getShips: getShips))
                                .environment(\.updatePilotStateHandler, updatePilotState)
                )
            }
            
            return AnyView(EmptyView())
        }
    }
    
    private func buildShipButton(shipPilot: ShipPilot, getShipsHandler: @escaping () -> ()) -> some View {
//        func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
//            // Get the dial status from the pilot state
//            if let data = shipPilot.pilotStateData {
//                print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
//                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
//                                                   dialStatus: data.dial_status,
//                                                   hasSystemPhaseAction: shipPilot.pilotStateData?.hasSystemPhaseAction ?? false)
//                                .environmentObject(SquadViewHandler(store: store))
//                                .environment(\.updatePilotStateHandler, updatePilotState)
//                )
//                                
//            }
//            
//            return AnyView(EmptyView())
//        }
        
        return Button(action: {
            onPilotTapped(shipPilot) })
        {
            ShipButton(shipPilot: shipPilot, getShips: getShipsHandler)
        }
    }
}

typealias UpdatePilotStateCallback = ((PilotStateData, PilotState) -> ())?

private struct ClosureKey: EnvironmentKey {
    static let defaultValue : UpdatePilotStateCallback = {_, _ in  }
}

extension EnvironmentValues {
    var updatePilotStateHandler : UpdatePilotStateCallback {
        get { self[ClosureKey.self] }
        set { self[ClosureKey.self] = newValue }
    }
}

struct Count {
    let count: Int32
    let limit: Int32
    
    var min: Count {
        let newCount = count - 1
        
        if (newCount) < 0 {
            return Count(count:0, limit: limit)
        } else {
            return Count(count:newCount, limit: limit)
        }
    }
    
    var max: Count {
        let newCount = count + 1
        
        if (newCount) > limit {
            return Count(count: limit, limit: limit)
        } else {
            return Count(count: newCount, limit: limit)
        }
    }
    
    static var zero: Count {
        return Count(count:0, limit: 20)
    }
    
    static var twelveCount: Count {
        return Count(count:0, limit: 12)
    }
}

extension Count : CustomStringConvertible {
    var description: String {
        "\(count)"
    }
}

extension Count : Equatable {}

