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

//// MARK:- Pilots
struct Redux_PilotCardView: View {
    let theme: Theme = WestworldUITheme()
    let shipPilot: ShipPilot
    @EnvironmentObject var viewFactory: ViewFactory
    @State var dialStatus: DialStatus
    let updatePilotStateCallback: (PilotStateData, PilotState) -> ()
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                HStack {
                    initiative
                    
                    Spacer()

                    pilotShipNames

                    Spacer()
                    
                    halfStatus
                }
                .padding(.leading, 5)
                .background(Color.black)
                
                Spacer()
                
                // https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
                
                buildPilotDetailsView()
                
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .multilineTextAlignment(.center)
        }
    }
    
    var body: some View {
        newView
            .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.BORDER_ACTIVE, lineWidth: 2)
        )
    }
    
    var halfStatus: some View {
        if let data = shipPilot.pilotStateData {
            if data.isDestroyed {
                return Text("Destroyed").padding(5).foregroundColor(Color.red)
            } else if data.isHalved {
                return Text("Half").padding(5).foregroundColor(Color.yellow)
            }
        }
        
        return Text("").padding(5).foregroundColor(Color.white)
    }
    
    var initiative: some View {
        Text("\(shipPilot.ship.pilots[0].initiative)")
            .font(.title)
            .bold()
            .foregroundColor(Color.orange)
    }
    
    var pilotShipNames: some View {
        VStack {
            Text("\(shipPilot.pilot.name)")
                .font(.body)
                .foregroundColor(Color.white)
            
            Text("\(shipPilot.ship.name)")
                .font(.caption)
                .foregroundColor(Color.white)
        }
    }
}

extension Redux_PilotCardView {
    func buildPilotDetailsView() -> some View {
        print("PAK_DialStatus buildPilotDetailsView() self.dialStatus = \(dialStatus)")
        
        return Redux_PilotDetailsView(updatePilotStateCallback: self.updatePilotStateCallback,
                                      shipPilot: self.shipPilot,
                                      displayUpgrades: true,
                                      displayHeaders: false,
                                      displayDial: true)
    }
}

struct Redux_PilotDetailsView: View {
    let updatePilotStateCallback: (PilotStateData, PilotState) -> ()
    let shipPilot: ShipPilot
    let displayUpgrades: Bool
    let displayHeaders: Bool
    let displayDial: Bool
    let theme: Theme = WestworldUITheme()
    @State var currentManeuver: String = ""
    
    func buildPointsView(half: Bool = false) -> AnyView {
        let points = half ? self.shipPilot.halfPoints : self.shipPilot.points
        let color = half ? Color.red : Color.blue
        let label = "\(points)"
        
        return AnyView(IndicatorView(label:label,
                                     bgColor: color,
                                     fgColor: theme.TEXT_FOREGROUND))
    }
    
    /*
     maneuverList
     ▿ 7 : 3L
       - speed : 3
       - bearing : DialControl.ManeuverBearing.L
       - difficulty : DialControl.ManeuverDifficulty.R
     ▿ 8 : 3T
       - speed : 3
       - bearing : DialControl.ManeuverBearing.T
       - difficulty : DialControl.ManeuverDifficulty.W
     */
    
    
    var dialViewNew: some View {
        let status = self.shipPilot.pilotStateData!.dial_status
        
        print("\(Date()) PAK_DialStatus dialViewNew \(self.shipPilot.id) \(self.shipPilot.pilotName) \(status)")
        
        return buildManeuverView(dialStatus: status)
            .padding(10)
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                // explicitly apply animation on toggle (choose either or)
                //withAnimation {
                self.flipDial()
                //}
            }
    }
    
    var names: some View {
        VStack {
            Text("\(self.shipPilot.ship.pilots[0].name)")
                .font(.title)
                .foregroundColor(theme.TEXT_FOREGROUND)
            
            Text("\(self.shipPilot.ship.name)")
                .font(.body)
                .foregroundColor(theme.TEXT_FOREGROUND)
        }
    }
    
    var upgrades: some View {
        VStack(alignment: .leading) {
            if (displayUpgrades) {
                ForEach(self.shipPilot.upgrades) { upgrade in
                    Text("\(upgrade.name)")
                        .foregroundColor(Color.white)
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            buildPointsView()
            
            buildPointsView(half: true)
            
            IndicatorView(label: "\(self.shipPilot.threshold)",
                bgColor: Color.yellow,
                fgColor: Color.black)
            
            // Pilot Details
//            names
            
            Spacer()
            
            // Upgrades
            upgrades
            
            Spacer()
            
//            dialView
            if (displayDial) {
                dialViewNew
            }
        }
        .padding(15)
        .onAppear() {
            print("\(Date()) PilotDetailsView.body.onAppear")
        }
    }
}

extension Redux_PilotDetailsView {
    func buildManeuverView(isFlipped: Bool) -> AnyView {
        let x = self.shipPilot.selectedManeuver
        var view: AnyView = AnyView(EmptyView())
        
        if isFlipped {
            if x.count > 0 {
                let m = Maneuver.buildManeuver(maneuver: x)
                view = m.view
            }
        } else {
            view = AnyView(Text("Dial").padding(15))
        }
    
        return AnyView(ZStack {
            Circle()
                .frame(width: 75, height: 75, alignment: .center)
                .foregroundColor(Color.black)

            view
        })
    }
    
    func buildManeuverView(dialStatus: DialStatus) -> AnyView {
        print("\(Date()) PAK_DialStatus buildManeuverView() \(self.shipPilot.id) \(dialStatus)")
        let ionManeuver = "1FB"
        
        var foregroundColor: Color {
            let ret: Color
            
            switch(dialStatus) {
                case .destroyed:
                    ret = Color.red
                default:
                    ret = Color.black
            }
            
            return ret
        }
        
        var strokeColor: Color {
            let ret: Color
            
            switch(dialStatus) {
                case .set:
                    ret = Color.white
                case .ionized:
                    ret = Color.red
                default:
                    ret = Color.clear
            }
            
            return ret
        }
        
        let x = self.shipPilot.selectedManeuver
        var view: AnyView = AnyView(EmptyView())
        
        switch(dialStatus) {
            case .hidden, .destroyed:
                view = AnyView(Text("").padding(15))
            case .ionized:
                view = Maneuver.buildManeuver(maneuver: ionManeuver).view
            case .revealed, .set:
                if x.count > 0 {
                    let m = Maneuver.buildManeuver(maneuver: x)
                    view = m.view
                }
        }
    
        return AnyView(ZStack {
            Circle()
                .frame(width: 75, height: 75, alignment: .center)
                .foregroundColor(foregroundColor)

            Circle()
                .stroke(strokeColor, lineWidth: 3)
                .frame(width: 75, height: 75, alignment: .center)

            view
        })
    }
    
    func flipDial() {
        /// Switch (PilotStateData_Change)
        if var data = self.shipPilot.pilotStateData {
            guard !data.isDestroyed else {
                // Do not flip if destroyed
                return
            }
            
            data.change(update: {
                var newPSD = $0
                
                print("\(Date()) PAK_\(#function) before pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                newPSD.dial_status.handleEvent(event: .dialTapped)
                
                // Update CoreData
                self.updatePilotStateCallback(newPSD, self.shipPilot.pilotState)
//                self.pilotStateService.updateState(newData: newPSD,
//                                                   state: self.shipPilot.pilotState)
                print("\(Date()) PAK_\(#function) after pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                
                // self.shipPilot.pilotState.json was updated but
                // the self.shipPilot property was NOT updated so no refesh taken
                // Hack to force refresh of view
//                self.objectWillChange.send()
            })
        }
        
        if let _ = self.shipPilot.pilotStateData {
            print("\(Date()) PAK_\(#function) pilotStateData id: \(self.shipPilot.id) dial_status: \(self.shipPilot.pilotStateData?.dial_status)")
        }
    }
}
