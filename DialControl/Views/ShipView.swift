//
//  ShipView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/25/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

struct ShipView: View {
    let squadPilot: SquadPilot
    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    @State var showCardOverlay: Bool = false
    
    let dial: [String] = [
                  "1TW",
                  "1YW",
                  "2TB",
                  "2BB",
                  "2FB",
                  "2NB",
                  "2YB",
                  "3LR",
                  "3TW",
                  "3BW",
                  "3FB",
                  "3NW",
                  "3YW",
                  "3PR",
                  "4FB",
                  "4KR",
                  "5FW"
                ]
    
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
            
            PilotDetailsView(pilot: squadPilot, displayUpgrades: true, displayHeaders: false)
                .padding(5)
//                .border(Color.green, width: 2)
            
            
            
            HStack(alignment: .top) {
                Image("Card_Pilot_103")
                    .resizable()
                    .scaledToFit()
//                    .frame(width: 600.0,height:600)
                    .border(Color.green, width: 2)
                    .onTapGesture { self.showCardOverlay.toggle() }
                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                
//                Color.clear.border(Color.green, width: 2)
                VStack(spacing: 5) {
                    HStack {
                        OverlayContentView(curColor: Color.purple, text: "Force Active").border(Color.green, width: 2)
                        OverlayContentView(curColor: Color.purple, text: "Force Inactive").border(Color.green, width: 2)
                    }
                    
                    HStack {
                        OverlayContentView(text: "Shield Active").border(Color.green, width: 2)
                        OverlayContentView(text: "Shield Inactive").border(Color.green, width: 2)
                    }
                    
                    HStack {
                        OverlayContentView(curColor: Color.yellow, text: "Charge Active").border(Color.green, width: 2)
                        OverlayContentView(curColor: Color.yellow, text: "Charge Inactive").border(Color.green, width: 2)
                    }
                }
                
                
                
//                WedgeView()
//                    .frame(width: 400.0,height:400)
//                    .border(Color.green, width: 2)
                
                DialView(temperature: 0, diameter: 400, currentManeuver: $currentManeuver, dial: dial, displayAngleRanges: false)
                    .frame(width: 400.0,height:400)
            }
            
            clearView
        }.border(Color.red, width: 2)
    }
}

struct TextOverlay: View {
    @Binding var isShowing : Bool
    
    var body: some View {
        Text("Charge")
            .frame(width: 100, height: 100)
            .background(Color.yellow)
            .cornerRadius(20)
            .opacity(self.isShowing ? 1 : 0)
    }
}
