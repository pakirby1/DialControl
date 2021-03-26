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
                    
                    halfStatus

                    Spacer()
                    
                    pilotShipNames

                    Spacer()
                    
                    healthStatus
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
    
    var healthStatus: some View {
        func buildStats(psd: PilotStateData) -> [HealthStat] {
            var stats: [HealthStat] = []
            
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
        
        if let data = shipPilot.pilotStateData {
            let stats: [HealthStat] = buildStats(psd: data)
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
            
            Spacer()
            
            upgrades
            
            Spacer()
            
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
