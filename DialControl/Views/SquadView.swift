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
    let squad: Squad = Squad.serializeJSON(jsonString: squadJSON)
    @EnvironmentObject var viewFactory: ViewFactory
    
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
                
                return matches[0]
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
                    
            // Add the upgrades from SquadPilot.upgrades
            let sensors: [Upgrade] = squadPilot.upgrades.sensors.map{ getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
            
            let talents: [Upgrade] = squadPilot.upgrades.talents.map{ getUpgrade(upgradeCategory: "talent", upgradeName: $0) }

            let modifications: [Upgrade] = squadPilot.upgrades.modifications.map{ getUpgrade(upgradeCategory: "modification", upgradeName: $0) }

            let upgrades = sensors + talents + modifications
            
            return ShipPilot(ship: ship,
                             upgrades: upgrades,
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
//    let pilot: SquadPilot
    let displayUpgrades: Bool
    let displayHeaders: Bool
    let theme: Theme = WestworldUITheme()
    
    @State var currentManeuver: String = ""
    
    var body: some View {
        HStack {
            Text("\(shipPilot.points)")
                .font(.title)
                .foregroundColor(theme.TEXT_FOREGROUND)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
            
            // Pilot Details
            VStack {
                Text("\(shipPilot.ship.pilots[0].name)")
                    .font(.title)
                    .foregroundColor(theme.TEXT_FOREGROUND)
                
                Text("\(shipPilot.ship.name)")
                    .font(.body)
                    .foregroundColor(theme.TEXT_FOREGROUND)
            }
            
            Spacer()
            
            // Upgrades
            VStack(alignment: .leading) {
                if (displayUpgrades) {
                    ForEach(shipPilot.upgrades) { upgrade in
                        Text("\(upgrade.name)")
                    }
//                    UpgradeSummaryView(category: "Talent Upgrades",
//                                       upgrades: shipPilot.upgrades.talents,
//                                       displayHeader: displayHeaders)
//
//                    UpgradeSummaryView(category: "Sensor Upgrades",
//                                       upgrades: shipPilot.upgrades.sensors,
//                                       displayHeader: displayHeaders)
//
//                    UpgradeSummaryView(category: "Modification Upgrades",
//                                       upgrades: shipPilot.upgrades.modifications,
//                                       displayHeader: displayHeaders)
                }
            }
            
            Spacer()
            
//            DialView(temperature: 0, diameter: 500, currentManeuver: $currentManeuver, dial: [
//              "1TW",
//              "1YW",
//              "2TB",
//              "2BB",
//              "2FB",
//              "2NB",
//              "2YB",
//              "3LR",
//              "3TW",
//              "3BW",
//              "3FB",
//              "3NW",
//              "3YW",
//              "3PR",
//              "4FB",
//              "4KR",
//              "5FW"
//            ])
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
