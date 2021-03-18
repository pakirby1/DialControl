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

struct Redux_SquadView: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    @State var isFirstPlayer: Bool = false
    let squad: Squad
    let squadData: SquadData
    
    init(squad: Squad, squadData: SquadData) {
        self.squad = squad
        self.squadData = squadData
    }
    
    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.back()
            }) {
                Text("< Faction Squad List")
            }
           
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
    
    var body: some View {
        return VStack {
            header
            Redux_SquadCardView(isFirstPlayer: $isFirstPlayer,
                                updateSquadCallback: self.updateSquad,
                                squad: self.squad,
                                squadData: self.squadData)
                .environmentObject(viewFactory)
                .environmentObject(store)
                .onAppear() {
                    print("Redux_SquadCardView.onAppear")
                }
        }
        .onAppear() {
            self.isFirstPlayer = self.squadData.firstPlayer
        }
    }
    
    func updateSquad(squadData: SquadData) {
        self.store.send(.squad(action: .updateSquad(squadData)))
    }
}

struct Redux_SquadCardView: View, DamagedSquadRepresenting {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    
    @State var shipPilots: [ShipPilot] = []
    @State var activationOrder: Bool = true
    @State private var revealAllDials: Bool = false
    @State private var displayResetAllConfirmation: Bool = false
    
    @Binding var isFirstPlayer: Bool
    
    let updateSquadCallback: (SquadData) -> ()
    let squad: Squad
    let squadData: SquadData
    let theme: Theme = WestworldUITheme()

    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    private var shipsView: AnyView {
        return AnyView(shipsGrid)
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
    
    var shipsListSection: some View {
        Section {
            ForEach(sortedShipPilots) { shipPilot in
                self.buildShipButton(shipPilot: shipPilot)
            }
        }
    }
    
    var shipsGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(0..<chunkedShips.count) { index in
                HStack {
                    ForEach(self.chunkedShips[index]) { shipPilot in
                        self.buildShipButton(shipPilot: shipPilot)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    var body: some View {
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
        
        let hide = Button(action: {
            self.revealAllDials.toggle()
            
            print("PAK_DialStatus_New Button: \(self.revealAllDials)")
        
            self.updateAllDials()
        }) {
            Text(self.revealAllDials ? "Hide" : "Reveal").foregroundColor(Color.white)
        }
        
        let reset = Button(action: {
            self.displayResetAllConfirmation = true
        }) {
            Text("Reset All")
                .font(.title)
                .foregroundColor(Color.red)
        }.alert(isPresented: $displayResetAllConfirmation) {
            Alert(
                title: Text("Reset All"),
                message: Text("Reset All Squads"),
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

                    hide

                    Spacer()

                    damaged
                }.padding(20)

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
        }
    }
}

extension Redux_SquadCardView {
    private func buildShipButton(shipPilot: ShipPilot) -> some View {
        func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
            // Get the dial status from the pilot state
            if let data = shipPilot.pilotStateData {
                print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                return AnyView(Redux_PilotCardView(shipPilot: shipPilot,
                                                   dialStatus: data.dial_status,
                                                   updatePilotStateCallback: self.updatePilotState)
                    .environmentObject(self.viewFactory))
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
    }
    
    private func processEngage() {
        self.activationOrder.toggle()
        self.squadData.engaged = self.activationOrder
        self.updateSquadCallback(self.squadData)
    }
    
    // TODO: Switch & AppStore
    private func loadShips() {
        logMessage("damagedPoints SquadCardView.loadShips")
        print("PAK_DialStatus SquadCardView.loadShips()")
        self.shipPilots = SquadCardViewModel.getShips(
            squad: self.squad,
            squadData: self.squadData)

        self.shipPilots.printAll(tag: "PAK_DialStatus self.shipPilots")

        self.shipPilots.forEach{ shipPilot in
            print("PAK_DialStatus SquadCardView.loadShips() \(shipPilot.id) \(shipPilot.pilotState.json ?? "No JSON")")
        }
    }
    
    private func resetAllShips() {
        sortedShipPilots.forEach{ shipPilot in
            /// Switch (PilotStateData_Change)
            if var data = shipPilot.pilotStateData {
                data.change(update: {
                    $0.reset()
                    
                    self.updatePilotState(pilotStateData: $0,
                                          pilotState: shipPilot.pilotState)
                })
            }
        }
        
        // Not sure why, but this forces a refresh of the ship status (Half, Destroyed)
        // It updatee the @State shipPilots
        
        // TODO: Switch & AppStore
        self.shipPilots = []
        // reload ships
        // TODO: Switch & AppStore
        loadShips()
    }
    
    private func updateAllDials() {
        sortedShipPilots.forEach{ shipPilot in
            /// Switch (PilotStateData_Change)
            if var data = shipPilot.pilotStateData {
                if data.dial_status != .destroyed {
                    data.change(update: {
                        print("PAK_DialStatus pilotStateData.id: \($0)")
                        let revealAllDialsStatus: DialStatus = self.revealAllDials ? .revealed : .hidden
                        $0.dial_status = revealAllDialsStatus
                        self.updatePilotState(pilotStateData: $0,
                                                           pilotState: shipPilot.pilotState)
                        print("PAK_DialStatus updateAllDials $0.dial_status = \(revealAllDialsStatus)")
                        print("PAK_DialStatus updateAllDials $0.dial_revealed = \(self.revealAllDials)")
                    })
                }
            }
        }
        
        // reload ships
        // TODO: Switch & AppStore
        loadShips()
    }
}

