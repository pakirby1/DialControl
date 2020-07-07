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

class SquadViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    var squad: Squad
    
    init(squad: Squad) {
        self.squad = squad
    }
}

struct SquadView: View {
    @State var maneuver: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    @ObservedObject var viewModel: SquadViewModel
    
    init(viewModel: SquadViewModel) {
        self.viewModel = viewModel
    }
    
    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.back()
            }) {
                Text("< Faction Squad List")
            }
            
            Spacer()
        }.padding(10)
    }
    
    var body: some View {
        VStack {
            header
            SquadCardView(squad: viewModel.squad)
                .environmentObject(viewFactory)
                .onAppear() {
                    print("SquadView.onAppear")
                }
        }.alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.alertText),
                  dismissButton: .default(Text("OK")))
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
            
            /// 7/7/2020
//            func buildAllUpgrades() {
//                var allUpgrades : [Upgrade] = []
//                
//                if let upgrades = squadPilot.upgrades {
//                    let astromechs : [Upgrade] = upgrades
//                        .astromechs
//                        .map{ getUpgrade(upgradeCategory: "astromech", upgradeName: $0) }
//                    
//                    let cannons : [Upgrade] = upgrades
//                        .cannons
//                        .map{ getUpgrade(upgradeCategory: "cannon", upgradeName: $0) }
//                    
//                    let cargos : [Upgrade] = upgrades
//                        .cargos
//                        .map{ getUpgrade(upgradeCategory: "cargo", upgradeName: $0) }
//                    
//                    let commands : [Upgrade] = upgrades
//                        .commands
//                        .map{ getUpgrade(upgradeCategory: "command", upgradeName: $0) }
//                    
//                    let configurations : [Upgrade] = upgrades
//                        .configurations
//                        .map{ getUpgrade(upgradeCategory: "configuration", upgradeName: $0) }
//                    
//                    let crews : [Upgrade] = upgrades
//                        .crews
//                        .map{ getUpgrade(upgradeCategory: "crew", upgradeName: $0) }
//                    
//                    let devices : [Upgrade] = upgrades
//                        .devices
//                        .map{ getUpgrade(upgradeCategory: "device", upgradeName: $0) }
//                    
//                    let forcepowers : [Upgrade] = upgrades
//                        .forcepowers
//                        .map{ getUpgrade(upgradeCategory: "forcepower", upgradeName: $0) }
//                    
//                    let gunners : [Upgrade] = upgrades
//                        .gunners
//                        .map{ getUpgrade(upgradeCategory: "gunner", upgradeName: $0) }
//                    
//                    let hardpoints : [Upgrade] = upgrades
//                        .hardpoints
//                        .map{ getUpgrade(upgradeCategory: "hardpoint", upgradeName: $0) }
//                    
//                    let illicits : [Upgrade] = upgrades
//                        .illicits
//                        .map{ getUpgrade(upgradeCategory: "illicit", upgradeName: $0) }
//                    
//                    let missiles : [Upgrade] = upgrades
//                        .missiles
//                        .map{ getUpgrade(upgradeCategory: "missile", upgradeName: $0) }
//                    
//                    let modifications : [Upgrade] = upgrades
//                        .modifications
//                        .map{ getUpgrade(upgradeCategory: "modification", upgradeName: $0) }
//                    
//                    let sensors : [Upgrade] = upgrades
//                        .sensors
//                        .map{ getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
//                    
//                    let tacticalrelays : [Upgrade] = upgrades
//                        .tacticalrelays
//                        .map{ getUpgrade(upgradeCategory: "tacticalrelay", upgradeName: $0) }
//                    
//                    let talents : [Upgrade] = upgrades
//                        .talents
//                        .map{ getUpgrade(upgradeCategory: "talent", upgradeName: $0) }
//                    
//                    let teams : [Upgrade] = upgrades
//                        .teams
//                        .map{ getUpgrade(upgradeCategory: "team", upgradeName: $0) }
//                    
//                    let techs : [Upgrade] = upgrades
//                        .techs
//                        .map{ getUpgrade(upgradeCategory: "tech", upgradeName: $0) }
//                    
//                    let titles : [Upgrade] = upgrades
//                        .titles
//                        .map{ getUpgrade(upgradeCategory: "title", upgradeName: $0) }
//                    
//                    let torpedos : [Upgrade] = upgrades
//                        .torpedos
//                        .map{ getUpgrade(upgradeCategory: "torpedo", upgradeName: $0) }
//                    
//                    let turrets : [Upgrade] = upgrades
//                        .turrets
//                        .map{ getUpgrade(upgradeCategory: "turret", upgradeName: $0) }
//                
//                    allUpgrades = astromechs + cannons + cargos + commands + configurations + crews + devices + forcepowers + gunners + hardpoints + illicits + missiles + modifications + sensors + tacticalrelays + talents + teams + techs + titles + torpedos + turrets
//                }
//            }
            
            var shipJSON: String = ""
                    
            print("shipName: \(squadPilot.ship)")
            print("pilotName: \(squadPilot.name)")
                    
            if let pilotFileUrl = shipLookupTable[squadPilot.ship] {
                print("pilotFileUrl: \(pilotFileUrl)")
                
                let type = pilotFileUrl.fileName.fileExtension()
                if let path = Bundle.main.path(forResource: pilotFileUrl.fileName,
                                               ofType: type,
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
            
            // Add the upgrades from SquadPilot.upgrades by iterating over the
            // UpgradeCardEnum cases and calling getUpgrade
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
                
//                allUpgrades = astromechs + cannons + cargos + commands + configurations + crews + devices + forcepowers + gunners + hardpoints + illicits + missiles + modifications + sensors + tacticalrelays + talents + teams + techs + titles + torpedos + turrets
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
                        self.viewFactory.viewType = .shipViewNew(shipPilot, self.squad)
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


/*
2020-07-04 08:31:46 +0000 ship NetworkCacheService.init
2020-07-04 08:31:51 +0000 ship NetworkCacheService.init
2020-07-04 08:31:53 +0000 upgrade NetworkCacheService.init
2020-07-04 08:32:02 +0000 ship NetworkCacheService.init
2020-07-04 08:32:15 +0000 ship NetworkCacheService.init
*/
