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

struct Redux_SquadView: View, DamagedSquadRepresenting {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    
    @State var activationOrder: Bool = true
    @State private var revealAllDials: Bool = false
    @State private var displayResetAllConfirmation: Bool = false
    @State var isFirstPlayer: Bool = false
    @State var victoryPoints: Int32 = 0
    
    let theme: Theme = WestworldUITheme()
    let squad: Squad
    let squadData: SquadData
    
    var shipPilots: [ShipPilot] {
//        loadShips()
        print("PAKshipPilots \(Date()) count: \(self.store.state.squad.shipPilots.count)")
        self.store.state.squad.shipPilots.forEach{ print("PAKshipPilots \(Date()) \($0.shipName)") }
        
        return self.store.state.squad.shipPilots
    }
    
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
    
    var revealedDialCount: Int {
        self.shipPilots.filter{
            guard let status = $0.pilotStateData?.dial_status else { return false }
            return status == .revealed
        }.count
    }
    
    var hiddenDialCount: Int {
        self.shipPilots.count - revealedDialCount
    }
    
    var dialsState : SquadDialsState {
        get {
            if revealedDialCount == self.shipPilots.count {
                return .revealed
            } else {
                return .hidden
            }
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
}

//MARK:- View
extension Redux_SquadView {
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
                row(label: "dialsState", text: self.dialsState.description)
                row(label: "revealedDialCount", text: self.revealedDialCount.description)
                row(label: "hiddenDialCount", text: self.hiddenDialCount.description)
                row(label: "shipPilots Count", text: self.shipPilots.count.description)
            }
        }
        
        var hideOrRevealAll: some View {
            func buildButton(_ newDialStatus: DialStatus) -> some View {
                let title: String = (newDialStatus == .hidden) ? "Hide" : "Reveal"
                
                return Button(action: {
                    func logDetails() {
                        print("PAK_Redux_SquadView dialsState: \(self.dialsState)")
                        print("PAK_Redux_SquadView revealedDialCount: \(self.revealedDialCount)")
                        print("PAK_Redux_SquadView shipPilots Count: \(self.shipPilots.count)")
                    }
                    
                    logDetails()
                    
        //            self.revealAllDials.toggle()
                    self.updateAllDials(newDialStatus: newDialStatus)

                    logDetails()

                    print("PAK_DialStatus_New Button: \(self.dialsState)")
                }) {
                    Text(title).foregroundColor(Color.white)
                }
            }
            
            return (self.dialsState == .hidden) ? buildButton(.revealed) : buildButton(.hidden)
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
                // TODO: Switch & AppStore
                if shipPilots.isEmpty {
                    emptySection
                } else {
                    shipsView
                }
                
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
            // TODO: Switch & AppStore
            executionTime("Perf Redux_SquadView.content.onAppear()") {
                self.loadShips()
                self.activationOrder = self.squadData.engaged
                print("PAKshipPilots \(Date()) .onAppear")
            }
        }
    }
    
    var body: some View {
        func onAppearBlock() {
            self.isFirstPlayer = self.squadData.firstPlayer
            self.victoryPoints = self.squadData.victoryPoints
        }
        
        return VStack {
            header
            content
        }
        .onAppear() {
            executionTime("Redux_SquadView.body.onAppear()") {
                onAppearBlock()
            }
        }
    }
    
    private func buildShipButton(shipPilot: ShipPilot) -> some View {
        func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
            // Get the dial status from the pilot state
            if let data = shipPilot.pilotStateData {
                print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
                                                   dialStatus: data.dial_status,
                                                   updatePilotStateCallback: self.updatePilotState, hasSystemPhaseAction: shipPilot.pilotStateData?.hasSystemPhaseAction ?? false)
                    .environmentObject(self.viewFactory)
                    .environmentObject(self.store))
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
extension Redux_SquadView {
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
        self.store.send(.squad(action: .updateSquad(squadData)))
    }
    
    func updatePilotState(pilotStateData: PilotStateData,
                                  pilotState: PilotState)
    {
        self.store.send(.squad(action: .updatePilotState(pilotStateData, pilotState)))
        
//        loadShips()
    }
    
    private func processEngage() {
        self.activationOrder.toggle()
        self.squadData.engaged = self.activationOrder
        self.updateSquad(squadData: self.squadData)
    }
    
    // TODO: Switch & AppStore
    private func loadShips() {
        // Make request to store to build the store.shipPilots
        
        logMessage("damagedPoints SquadCardView.loadShips")
        print("PAK_DialStatus SquadCardView.loadShips()")
        store.send(.squad(action: .getShips(self.squad, self.squadData)))
    }
    
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
        self.loadShips()
    }
    
    private func updateAllDials() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                if data.dial_status != .destroyed {
                    data.change(update: {
                        print("PAK_DialStatus pilotStateData.id: \($0)")
                        let revealAllDialsStatus: DialStatus = (self.dialsState == .revealed) ? .revealed : .hidden
                        $0.dial_status = revealAllDialsStatus
                        
                        self.updatePilotState(pilotStateData: $0,
                                                           pilotState: shipPilot.pilotState)
                        print("PAK_DialStatus updateAllDials $0.dial_status = \(revealAllDialsStatus)")
                        print("PAK_DialStatus updateAllDials $0.dial_revealed = \(self.revealAllDials)")
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

struct CustomToggleView : View {
    let label: String
    @Binding var binding : Bool
    
    var body: some View {
        HStack {
            Text(label)
            Toggle("", isOn: self.$binding).labelsHidden()
        }
    }
}

protocol VictoryPointsRepresentable {
    var squadData: SquadData { get set }
    var store: MyAppStore { get set }
    func updateSquad(squadData: SquadData)
}

extension VictoryPointsRepresentable {
    func updateSquad(squadData: SquadData) {
        self.store.send(.squad(action: .updateSquad(squadData)))
    }
}
