//
//  FactionSquadList.swift
//  DialControl
//
//  Created by Phil Kirby on 4/28/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let faction: String
    
    var body: some View {
        VStack {
            headerView
                .padding(5)
            
            squadList
            
            Spacer()
        }
    }
    
    var titleView: some View {
        Text("\(faction)")
            .font(.largeTitle)
    }
    
    var headerView: some View {
        HStack {
            Button(action: {
                self.viewFactory.viewType = .factionFilterView(.galactic_empire)
            }) {
                Text("Filter")
            }
            
            Spacer()
            titleView
            Spacer()
            
            Button(action: {
                self.viewFactory.viewType = .squadImportView
            }) {
                Text("Import XWS")
            }
        }
    }
    
    var squadList: some View {
        VStack {
            FactionSquadCard(name: "Worlds Champion 2019").environmentObject(viewFactory)
            FactionSquadCard(name: "SaiDuchessTurr3Academies").environmentObject(viewFactory)
            FactionSquadCard(name: "VaderSoontirEcho").environmentObject(viewFactory)
            FactionSquadCard(name: "VagabondMaarekFifthBrotherTurr").environmentObject(viewFactory)
        }.padding(10)
    }
}

struct FactionSquadCard: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let theme: Theme = WestworldUITheme()
    
    let points: Int = 200
    let name: String
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(theme.BUTTONBACKGROUND)
            .frame(width: 800, height: 80)
            .overlay(border)
        
//            .stroke(lineWidth: 3.0)
        
//            .foregroundColor(Color.blue)
//
    }
    
    var pointsView: some View {
        Text("\(points)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var nameView: some View {
        Text(name)
            .font(.title)
            .lineLimit(1)
            .foregroundColor(theme.TEXT_FOREGROUND)
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(theme.BORDER_INACTIVE, lineWidth: 3)
    }
    
    var body: some View {
        Button(action: {
            self.viewFactory.viewType = .squadView
        }) {
            ZStack {
                background
                pointsView.offset(x: -350, y: 0)
                nameView
            }
        }
    }
}
