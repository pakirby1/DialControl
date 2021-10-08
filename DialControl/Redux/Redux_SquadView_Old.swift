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
            BackButtonView().environmentObject(viewFactory)
           
            Toggle(isOn: self.$isFirstPlayer.didSet{
                // Hack because swift thinks I don't want to perform
                // an assignment (=) vs. a boolean check (==)
                let x = $0
                self.squadData.firstPlayer = x
                self.updateSquad(squadData: self.squadData)
            }){
                Text("First Player")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
        }.padding(10)
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
            self.loadShips()
            self.activationOrder = self.squadData.engaged
            print("PAKshipPilots \(Date()) .onAppear")
        }
    }
    
    var body: some View {
        return VStack {
            header
            content
        }
        .onAppear() {
            self.isFirstPlayer = self.squadData.firstPlayer
        }
    }
}

//MARK:- Behavior
extension Redux_SquadView {
    func updateSquad(squadData: SquadData) {
        self.store.send(.squad(action: .updateSquad(squadData)))
    }

    private func buildShipButton(shipPilot: ShipPilot) -> some View {
        func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
            // Get the dial status from the pilot state
            if let data = shipPilot.pilotStateData {
                print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
                                                   dialStatus: data.dial_status,
                                                   updatePilotStateCallback: self.updatePilotState)
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
        
        self.shipPilots.printAll(tag: "PAK_DialStatus self.shipPilots")

        self.shipPilots.forEach{ shipPilot in
            print("PAK_DialStatus SquadCardView.loadShips() \(shipPilot.id) \(shipPilot.pilotState.json ?? "No JSON")")
        }
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
