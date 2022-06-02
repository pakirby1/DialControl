//
//  Redux_PilotCardView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/18/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

struct Redux_PilotCardView: View, ShipIDRepresentable {
    let theme: Theme = WestworldUITheme()
    let shipPilot: ShipPilot
    @EnvironmentObject var viewFactory: ViewFactory
    @State var dialStatus: DialStatus
    let updatePilotStateCallback: (PilotStateData, PilotState) -> ()
    @EnvironmentObject var store: MyAppStore
    @State var hasSystemPhaseAction: Bool
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack(spacing: 0) {
                HStack {
                    initiative
                    
                    shipID
                    
                    Spacer()
                    
                    pilotShipNames

                    Spacer()
                    
                    systemPhaseToggle.zIndex(1.0)

                    DamagedStatusView(shipPilot: shipPilot)
                }
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                .background(Color.black)
                // https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
                
                HStack {
                    Spacer()
                    healthStatus
                    Spacer()
                }.background(Color.black)
                
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
    
    var systemPhaseToggle: some View {
        Toggle(isOn: self.$hasSystemPhaseAction){
            EmptyView()
        }
        .labelsHidden() // Label takes up too much space, so just hide it.
        .onTapGesture {
            /*
            // Necessary to receive tap events while in a ZStack
            withAnimation { hasSystemPhaseAction.toggle() }
            */
            hasSystemPhaseAction.toggle()
            print("systemPhaseToggle.onTapGesture hasSystemPhaseAction = \(self.hasSystemPhaseAction)")
            measure(name: "setSystemPhaseState") {
                self.setSystemPhaseState(state: self.hasSystemPhaseAction)
            }
        }
    }
    
    var healthStatus: some View {
        func buildStats(psd: PilotStateData) -> [HealthStat] {
            var stats: [HealthStat] = []
            
            if psd.adjusted_defense > 0 {
                stats.append(HealthStat(type: .agility, value: psd.adjusted_defense))
            }
            
            if psd.hullMax > 0 {
                stats.append(HealthStat(type: .hull, value: psd.getActive(type: .hull)))
            }
            
            if psd.shieldsMax > 0 {
                stats.append(HealthStat(type: .shield, value: psd.getActive(type: .shield)))
            }
            
            if psd.forceMax > 0 {
                stats.append(HealthStat(type: .force, value: psd.getActive(type: .force)))
            }
            
            if psd.chargeMax > 0 {
                stats.append(HealthStat(type: .charge, value: psd.getActive(type: .charge)))
            }
            
            return stats
        }
        
        func buildFiringArcStats() -> [HealthStat] {
            return shipPilot.ship.firingArcs.map{
                $0.healthStat
            }
        }
        
        if let data = shipPilot.pilotStateData {
            let stats: [HealthStat] = buildFiringArcStats() + buildStats(psd: data)
            return HealthStatsView(healthStats: stats)
        }
        
        return HealthStatsView(healthStats: [])
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
                                      displayDial: true).environmentObject(self.store)
    }
    
    func setSystemPhaseState(state: Bool) {
        measure(name: "setSystemPhaseState(state:\(state)") {
            if let data = shipPilot.pilotStateData {
                let name = shipPilot.pilotName
                data.change(update: { psd in
                    
                    print("Redux_PilotCardView.setSystemPhaseState name: \(name) state: \(state)")

                    psd.hasSystemPhaseAction = state
//
                    self.store.send(.squad(action: .updatePilotState(psd, self.shipPilot.pilotState)))

    //                self.store.send(.squad(action: .updatePilotState($0, self.shipPilot.pilotState)))
                    print("Redux_PilotCardView $0.hasSystemPhaseAction = \(String(describing: psd.hasSystemPhaseAction))")
                })
            }
        }
    }
}

struct DamagedStatusView: View {
    let shipPilot: ShipPilot
    
    var body: some View {
        if let data = shipPilot.pilotStateData {
            if data.isDestroyed {
                return Text("Destroyed").foregroundColor(Color.red)
            } else if data.isHalved {
                return Text("Half").foregroundColor(Color.yellow)
            }
        }
        
        return Text("").foregroundColor(Color.white)
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
    @EnvironmentObject var store: MyAppStore
    
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
        VStack(spacing: 0) {
            HStack {
                buildPointsView()
                
                buildPointsView(half: true)

                Spacer()
                
                upgrades
                
                Spacer()
                
                if (displayDial) {
                    dialViewNew
                }
            }
            .padding(.leading, 10)
            .onAppear() {
                print("\(Date()) PilotDetailsView.body.onAppear")
            }
        }
        
    }
}

extension Redux_PilotDetailsView {
    func buildPointsView(half: Bool = false) -> AnyView {
        let points = half ? self.shipPilot.halfPoints : self.shipPilot.points
        let color = half ? Color.red : Color.blue
        let label = "\(points)"
        
        return AnyView(IndicatorView(label:label,
                                     bgColor: color,
                                     fgColor: theme.TEXT_FOREGROUND))
    }
    
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
            case .revealed, .set, .ionized:
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

            if dialStatus == .ionized {
                Text("Ion")
                    .foregroundColor(Color.red)
                    .offset(x:0, y: 25)
            }

            view
        })
    }
    
    func flipDial() {
        if var data = self.shipPilot.pilotStateData {
            guard !data.isDestroyed else {
                // Do not flip if destroyed
                return
            }
            
            /*
            data.change(update: {
                var newPSD = $0
                
                print("\(Date()) PAK_\(#function) before pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                newPSD.dial_status.handleEvent(event: .dialTapped)
                
                // Update CoreData
                self.pilotStateService.updateState(newData: newPSD,
                                                   state: self.shipPilot.pilotState)
                print("\(Date()) PAK_\(#function) after pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                
                // self.shipPilot.pilotState.json was updated but
                // the self.shipPilot property was NOT updated so no refesh taken
                // Hack to force refresh of view
                self.objectWillChange.send()
            })
            */
            
            self.store.send(.squad(action: .flipDial(data, shipPilot.pilotState)))
            
            print("\(Date()) PAK_\(#function) pilotStateData id: \(self.shipPilot.id) dial_status: \(self.shipPilot.pilotStateData?.dial_status)")
        }
    }
}
