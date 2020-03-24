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
    let squad: Squad
    @EnvironmentObject var viewFactory: ViewFactory
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.red)

            VStack(alignment: .leading) {
                Text(squad.name)
                    .font(.title)
                    .foregroundColor(.black)
                    .border(Color.blue, width: 2)

                Text("Points: \(squad.points)")
                    .font(.title)
                    .foregroundColor(.black)
                
////                NavigationView {
////                    ForEach(squad.pilots) { pilot in
////                        NavigationLink(destination:
////                            ShipView(squadPilot: pilot)
////                        ) {
////                            PilotCardView(pilot: pilot)
////                        }
////                    }
////                }
//
//                NavigationView {
//                    List(squad.pilots) { pilot in
//                      NavigationLink(
//                        destination: ShipView(squadPilot: pilot)) {
//                            PilotCardView(pilot: pilot)
//                      }
//                    }
//                }.navigationViewStyle(StackNavigationViewStyle())
                
                ForEach(squad.pilots) { pilot in
                    Button(action: {
                        self.viewFactory.viewType = .shipView(pilot)
                    }) {
                        PilotCardView(pilot: pilot)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 600, height: 600)
    }
}

struct PilotDetailsView: View {
    let pilot: SquadPilot
    let displayUpgrades: Bool
    @State var currentManeuver: String = "1LT"
    
    var body: some View {
        HStack {
            Text("\(pilot.points)")
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
            //                        .border(Color.blue, width: 2)
            
            VStack {
                Text(pilot.name)
                    .font(.title)
                
                Text(pilot.ship)
                    .font(.body)
                
            }
            .border(Color.blue, width: 2)
            
            Spacer()
            
            VStack {
                if (displayUpgrades) {
                    UpgradeSummaryView(category: "Talent Upgrades", upgrades: pilot.upgrades.talents)
                    UpgradeSummaryView(category: "Sensor Upgrades", upgrades: pilot.upgrades.sensors)
                    UpgradeSummaryView(category: "Modification Upgrades", upgrades: pilot.upgrades.modifications)
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
        }
    }
}

struct UpgradeSummaryView : View {
    let category: String
    let upgrades: [String]
    
    var body: some View {
        VStack {
            if (upgrades.count > 0) {
                Text(category).font(.title)
                
                ForEach(upgrades, id:\.self) { upgrade in
                    Text("\(upgrade)")
                }
            }
        }
    }
}
struct PilotCardView: View {
    let pilot: SquadPilot
    let theme: Theme = LightTheme()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                PilotDetailsView(pilot: pilot, displayUpgrades: false)
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 500, height: 100)
    }
}

struct CardView: View {
    let content: () -> AnyView
    
    var body: some View {
        VStack {
            content()
        }
    }
}

struct ShipView: View {
    let squadPilot: SquadPilot
    @EnvironmentObject var viewFactory: ViewFactory
    
    var backButtonView: some View {
        Button(action: {
            self.viewFactory.viewType = .squadView
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Back to Squad")
            }
        }.padding(5)
    }
    
    var clearView: some View {
        Color
            .clear
            .border(Color.red, width: 5)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                backButtonView
                    .border(Color.blue, width: 2)
            }
            .frame(width: 600, height: 50, alignment: .leading)
            .border(Color.blue, width: 2)
            
            PilotDetailsView(pilot: squadPilot, displayUpgrades: true)
                .padding(5)
                .border(Color.green, width: 2)
            
            clearView
        }.border(Color.red, width: 2)
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
