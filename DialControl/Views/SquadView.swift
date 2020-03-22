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
    
    var body: some View {
        SquadCardView(squad: squad)
            .onAppear() {
                print("SquadView.onAppear")
            }
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

struct SquadCardView: View {
    let squad: Squad

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.red)

            VStack {
                Text(squad.name)
                    .font(.largeTitle)
                    .foregroundColor(.black)

                Text("Points: \(squad.points)")
                    .font(.title)
                    .foregroundColor(.gray)
                
                ForEach(squad.pilots) { pilot in
                    Text("\(pilot.name) \(pilot.points) \(pilot.ship)")
                }
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 450, height: 250)
    }
}
