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
    let displayHeaders: Bool
    
    @State var currentManeuver: String = ""
    
    var body: some View {
        HStack {
            Text("\(pilot.points)")
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack {
                Text(pilot.name)
                    .font(.title)
                
                Text(pilot.ship)
                    .font(.body)
            }
            
            Spacer()
            
            VStack {
                if (displayUpgrades) {
                    UpgradeSummaryView(category: "Talent Upgrades",
                                       upgrades: pilot.upgrades.talents,
                                       displayHeader: displayHeaders)
                    
                    UpgradeSummaryView(category: "Sensor Upgrades",
                                       upgrades: pilot.upgrades.sensors,
                                       displayHeader: displayHeaders)
                    
                    UpgradeSummaryView(category: "Modification Upgrades",
                                       upgrades: pilot.upgrades.modifications,
                                       displayHeader: displayHeaders)
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
    
    var body: some View {
        VStack {
            if (upgrades.count > 0) {
                if (displayHeader) {
                    Text(category).font(.title)
                }
                
                ForEach(upgrades, id:\.self) { upgrade in
                    Text("\(upgrade)")
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


struct PilotCardView: View {
    let pilot: SquadPilot
    let theme: Theme = LightTheme()
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                HStack {
                    Spacer()
                
                    Text("\(pilot.name)")
                        .font(.title)
                        .foregroundColor(Color.white)
                    
                    Spacer()
                }.background(Color.black)
                
                PilotDetailsView(pilot: pilot, displayUpgrades: true, displayHeaders: false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .multilineTextAlignment(.center)
        }
    }
    
    var body: some View {
        newView.overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 2)
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
