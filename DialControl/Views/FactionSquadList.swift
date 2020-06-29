//
//  FactionSquadList.swift
//  DialControl
//
//  Created by Phil Kirby on 4/28/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

class FactionSquadListViewModel : ObservableObject {
    @Published var squadNames : [String] = []
    
    init() {
        self.squadNames = ["Worlds Champion 2019",
                       "SaiDuchessTurr3Academies",
                       "VaderSoontirEcho",
                       "VagabondMaarekFifthBrotherTurr"]
    }
}

struct FactionSquadList: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let faction: String
    let viewModel = FactionSquadListViewModel()
    
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
            ForEach(self.viewModel.squadNames, id:\.self) { name in
                FactionSquadCard(viewModel: FactionSquadCardViewModel(name: name)).environmentObject(self.viewFactory)
            }
        }.padding(10)
    }
}

class FactionSquadCardViewModel : ObservableObject {
    let points: Int = 200
    let name: String
    let theme: Theme = WestworldUITheme()
    
    init(name: String) {
        self.name = name
    }
    
    var buttonBackground: Color {
        theme.BUTTONBACKGROUND
    }
    
    var textForeground: Color {
        theme.TEXT_FOREGROUND
    }
    
    var border: Color {
        theme.BORDER_INACTIVE
    }
}

struct FactionSquadCard: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let viewModel: FactionSquadCardViewModel
    
    init(viewModel: FactionSquadCardViewModel) {
        self.viewModel = viewModel
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var pointsView: some View {
        Text("\(viewModel.points)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var nameView: some View {
        Text(viewModel.name)
            .font(.title)
            .lineLimit(1)
            .foregroundColor(viewModel.textForeground)
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
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
