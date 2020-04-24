//
//  SquadView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

struct SquadView: View {
    @State var maneuver: String = ""
    let squad: Squad
    @EnvironmentObject var viewFactory: ViewFactory
    
    init(jsonString: String) {
        self.squad = Squad.serializeJSON(jsonString: New_squadJSON)
    }
    
    var body: some View {
        SquadCardView(squad: squad)
            .environmentObject(viewFactory)
            .onAppear() {
                print("SquadView.onAppear")
            }
    }
}

struct SquadCardView: View {
    func getShips() {
        func getShip(squadPilot: SquadPilot) -> ShipPilot {
            func getJSON(forType: String, inDirectory: String) -> String {
                // Read json from file: forType.json
                let jsonFileName = "\(forType)"
                var upgradeJSON = ""
                
                if let path = Bundle.main.path(forResource: jsonFileName,
                                               ofType: "json",
                                               inDirectory: inDirectory)
                {
                    print("path: \(path)")
                    
                    do {
                        upgradeJSON = try String(contentsOfFile: path)
                        print("upgradeJSON: \(upgradeJSON)")
                    } catch {
                        print("error reading from \(path)")
                    }
                }
                
                //            return modificationsUpgradesJSON
                return upgradeJSON
            }
            
            func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
                let jsonString = getJSON(forType: upgradeCategory, inDirectory: "upgrades")
                
                let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
                
                let matches: [Upgrade] = upgrades.filter({ $0.xws == upgradeName })
                
                let upgrade = matches[0]
                
                return upgrade
            }
            
            var shipJSON: String = ""
                    
            print("shipName: \(squadPilot.ship)")
            print("pilotName: \(squadPilot.name)")
                    
            if let pilotFileUrl = shipLookupTable[squadPilot.ship] {
                print("pilotFileUrl: \(pilotFileUrl)")
                
                if let path = Bundle.main.path(forResource: pilotFileUrl.fileName,
                                               ofType: "json",
                                               inDirectory: pilotFileUrl.directoryPath)
                {
                    print("path: \(path)")
                    
                    do {
                        shipJSON = try String(contentsOfFile: path)
                        print("jsonData: \(shipJSON)")
                    } catch {
                        print("error reading from \(path)")
                    }
                }
            }
            
            var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
            let foundPilots: Pilot = ship.pilots.filter{ $0.xws == squadPilot.name }[0]

            ship.pilots.removeAll()
            ship.pilots.append(foundPilots)
            
            var allUpgrades : [Upgrade] = []
            
            // Add the upgrades from SquadPilot.upgrades
            if let upgrades = squadPilot.upgrades {
                let sensors: [Upgrade] = upgrades
                    .sensors
                    .map{ getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
                
                let talents: [Upgrade] = upgrades
                    .talents
                    .map{ getUpgrade(upgradeCategory: "talent", upgradeName: $0) }

                let modifications: [Upgrade] = upgrades
                    .modifications
                    .map{ getUpgrade(upgradeCategory: "modification", upgradeName: $0) }
                
                allUpgrades = sensors + talents + modifications
            }
            
            return ShipPilot(ship: ship,
                             upgrades: allUpgrades,
                             points: squadPilot.points)
        }
        
        self.shipPilots = self.squad.pilots.map{ getShip(squadPilot: $0) }
    }
    
    let squad: Squad
    let theme: Theme = WestworldUITheme()
    @EnvironmentObject var viewFactory: ViewFactory
    @State var shipPilots: [ShipPilot] = []
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(theme.BORDER_INACTIVE)

            VStack(alignment: .leading) {
                HStack {
                    Text("\(squad.points)")
                        .font(.title)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    Text(squad.name)
                        .font(.title)
                        .lineLimit(1)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                }
                
                ForEach(shipPilots) { shipPilot in
                    Button(action: {
                        self.viewFactory.viewType = .shipViewNew(shipPilot)
                    }) {
                        PilotCardView(shipPilot: shipPilot)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .onAppear(perform: getShips)
        .frame(width: 600, height: 600)
    }
}

struct PilotCardView: View {
    let theme: Theme = WestworldUITheme()
    let shipPilot: ShipPilot
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                HStack {
                    Spacer()
                
                    Text("\(shipPilot.ship.name)")
                        .font(.title)
                        .foregroundColor(Color.white)
                    
                    Spacer()
                }.background(Color.black)
                
                Spacer()
                
                PilotDetailsView(shipPilot: shipPilot,
                                 displayUpgrades: true,
                                 displayHeaders: false)
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
}

struct PilotDetailsView: View {
    let shipPilot: ShipPilot
    let displayUpgrades: Bool
    let displayHeaders: Bool
    let theme: Theme = WestworldUITheme()
    
    @State var currentManeuver: String = ""
    
    var points: some View {
        Text("\(shipPilot.points)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var names: some View {
        VStack {
            Text("\(shipPilot.ship.pilots[0].name)")
                .font(.title)
                .foregroundColor(theme.TEXT_FOREGROUND)
            
            Text("\(shipPilot.ship.name)")
                .font(.body)
                .foregroundColor(theme.TEXT_FOREGROUND)
        }
    }
    
    var upgrades: some View {
        VStack(alignment: .leading) {
            if (displayUpgrades) {
                ForEach(shipPilot.upgrades) { upgrade in
                    Text("\(upgrade.name)")
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            points
            
            // Pilot Details
            names
            
            Spacer()
            
            // Upgrades
            upgrades
            
            Spacer()
            
        }.padding(5)
    }
}

struct UpgradeSummaryView : View {
    let category: String
    let upgrades: [String]
    let displayHeader: Bool
    let theme: Theme = WestworldUITheme()
    
    var body: some View {
        VStack {
            if (upgrades.count > 0) {
                if (displayHeader) {
                    Text(category)
                        .font(.title)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                }
                
                ForEach(upgrades, id:\.self) { upgrade in
                    Text("\(upgrade)")
                        .foregroundColor(self.theme.TEXT_FOREGROUND)
                }
            }
        }
    }
}

struct CardViewModel {
    let strokeColor: Color
    let strokeWidth: CGFloat
    let backgroundColor: Color
    let headerText: String
    let headerBackgroundColor: Color
    let headerTextColor: Color
    let cornerRadius: CGFloat
}

// content wrapper pattern
//struct TrackinAreaView<Content>: View where Content : View {
//    let onMove: (NSPoint) -> Void
//    let content: () -> Content
//
//    init(onMove: @escaping (NSPoint) -> Void, @ViewBuilder content: @escaping () -> Content) {
//        self.onMove = onMove
//        self.content = content
//    }
//
//    var body: some View {
//        TrackingAreaRepresentable(onMove: onMove, content: self.content())
//    }
//}
//
// CardView<PilotDetailsView>
// CardView<UpgradeCardView>
struct CardView<Content: View>: View {
    let cardViewModel: CardViewModel
    let content: () -> Content
    
    init(cardViewModel: CardViewModel, @ViewBuilder content: @escaping () -> Content) {
        self.cardViewModel = cardViewModel
        self.content = content
    }
        
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: cardViewModel.cornerRadius, style: .continuous)
                .fill(cardViewModel.backgroundColor)

            VStack {
                HStack {
                    Spacer()
                
                    Text("\(cardViewModel.headerText)")
                        .font(.title)
                        .foregroundColor(cardViewModel.headerTextColor)
                    
                    Spacer()
                }.background(cardViewModel.headerBackgroundColor)
                
//                PilotDetailsView(pilot: pilot, displayUpgrades: true, displayHeaders: false)
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: cardViewModel.cornerRadius, style: .continuous))
            .multilineTextAlignment(.center)
        }
    }
    
    var body: some View {
        newView.overlay(
            RoundedRectangle(cornerRadius: cardViewModel.cornerRadius)
                .stroke(cardViewModel.strokeColor, lineWidth: cardViewModel.strokeWidth)
        )
    }
}



struct OldCardView: View {
    let content: () -> AnyView
    
    var body: some View {
        VStack {
            content()
        }
    }
}

struct NavigationContentView : View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello World")
                NavigationLink(destination:Text("Hello")) {
                    Text("Do Something")
                }
            }
        }
    }
}
