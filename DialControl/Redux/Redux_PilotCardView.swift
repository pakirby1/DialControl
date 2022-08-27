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
    var shipPilot: ShipPilot
    @State var dialStatus: DialStatus
    @State var hasSystemPhaseAction: Bool
    @EnvironmentObject var handler: SquadViewHandler
    
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
                    
                    systemPhaseToggle
                        .zIndex(-1)

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
        .onAppear() {
            global_os_log("FeatureId.firstPlayerUpdate","Redux_PilotCardView.newView.onAppear \(shipPilot.pilotName) \(String(describing: shipPilot.pilotStateData?.hasSystemPhaseAction))")
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
        Toggle(isOn: $hasSystemPhaseAction){
            EmptyView()
        }
        .fixedSize()
        .contentShape(Rectangle())
        .onChange(of: hasSystemPhaseAction) { action in
            global_os_log("FeatureId.firstPlayerUpdate","Redux_PilotCardView.systemPhaseToggle.onTapGesture hasSystemPhaseAction = \(action)")
            measure(name: "setSystemPhaseState") {
                handler.setSystemPhaseState(shipPilot: shipPilot, state: action)
            }
        }
        .onTapGesture {} // hide the Redux_PilotCardView.onTapGesture()
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
        
        return Redux_PilotDetailsView(shipPilot: self.shipPilot,
                                      displayUpgrades: true,
                                      displayHeaders: false,
                                      displayDial: true)
            .environmentObject(handler)
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
    let shipPilot: ShipPilot
    let displayUpgrades: Bool
    let displayHeaders: Bool
    let displayDial: Bool
    let theme: Theme = WestworldUITheme()
    @State var currentManeuver: String = ""
    @EnvironmentObject var handler: SquadViewHandler
    
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
//        func color(upgrade: Upgrade) -> Color {
//            guard let upgradeState = getUpgradeStateData(upgrade: upgrade) else { return Color.white }
//
//            guard let charge_active = upgradeState.charge_active else { return Color.white }
//            guard let charge_inactive = upgradeState.charge_inactive else { return Color.white }
//
//            if charge_active == 0 {
//                return Color.red
//            }
//        }
        
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

                IndicatorView(label: "\(self.shipPilot.threshold)",
                    bgColor: Color.yellow,
                    fgColor: Color.black)
                
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
            
            handler.flipDial(shipPilot: shipPilot)
            
            print("\(Date()) PAK_\(#function) pilotStateData id: \(self.shipPilot.id) dial_status: \(self.shipPilot.pilotStateData?.dial_status)")
        }
    }
}

class SquadViewHandler: ObservableObject {
    var store: MyAppStore
    
    init(store: MyAppStore) {
        self.store = store
    }
    
    /// Updates a Bool on a pilot state data
    /// - Parameters:
    ///   - label: Label for logging
    ///   - state: Bool
    ///   - handler: what function should be called on the pilot state data
    func updateState<T: CustomStringConvertible>(label: String,
                                                         shipPilot: ShipPilot,
                                                         state: T,
                                                         handler: (inout PilotStateData) -> ())
    {
        measure(name: "\(label)(state:\(state)") {
            if let data = shipPilot.pilotStateData {
                let name = shipPilot.pilotName
                data.change(update: { psd in
                    print("\(label) name: \(name) state: \(state)")
                    
                    handler(&psd)
                    updatePilotState(pilotStateData: psd,
                                     pilotState: shipPilot.pilotState)
                })
            }
        }
    }
}

extension SquadViewHandler {
    func updatePilotState(pilotStateData: PilotStateData,
                          pilotState: PilotState)
    {
        self.store.send(.squad(action: .updatePilotState(pilotStateData, pilotState)))
    }
    
    func updateSystemPhaseState(shipPilot: ShipPilot, value: Bool) {
        updateState(label: "FeatureId.firstPlayerUpdate", shipPilot: shipPilot, state: value) {
            $0.updateSystemPhaseAction(value: value)
        }
    }
    
    func setSystemPhaseState(shipPilot: ShipPilot, state: Bool) {
        func setSystemPhaseState_New(state: Bool) {
            updateSystemPhaseState(shipPilot: shipPilot, value: state)
        }
        
        func setSystemPhaseState_Old(shipPilot: ShipPilot, state: Bool) {
            measure(name: "setSystemPhaseState(state:\(state)") {
                if let data = shipPilot.pilotStateData {
                    let name = shipPilot.pilotName
                    data.change(update: { psd in
                        
                        print("Redux_PilotCardView.setSystemPhaseState name: \(name) state: \(state)")

                        psd.hasSystemPhaseAction = state

                        updatePilotState(pilotStateData: psd, pilotState: shipPilot.pilotState)

//                        self.store.send(.squad(action: .updatePilotState(psd, self.shipPilot.pilotState)))

        //                self.store.send(.squad(action: .updatePilotState($0, self.shipPilot.pilotState)))
                        print("Redux_PilotCardView $0.hasSystemPhaseAction = \(String(describing: psd.hasSystemPhaseAction))")
                    })
                }
            }
        }
        
//        setSystemPhaseState_Old(shipPilot: shipPilot,state: state)
        setSystemPhaseState_New(state: state)
    }
    
    func flipDial(shipPilot: ShipPilot) {
        if let data = shipPilot.pilotStateData {
            store.send(.squad(action: .flipDial(data, shipPilot.pilotState)))
        }
    }
}
