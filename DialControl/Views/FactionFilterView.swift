//
//  FactionFilterView.swift
//  DialControl
//
//  Created by Phil Kirby on 5/3/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct FactionFilterView: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let faction: Faction

    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.view(viewType: .factionSquadList(self.faction))
            }) {
                Text("< Faction Squad List")
            }
            
            Spacer()
            
            Text(self.faction.rawValue)
                .font(.largeTitle)
            
            Spacer()
            Spacer()
            
        }.padding(10)
    }
    
    func factionList() -> some View {
        List(Faction.allCases, id:\.self) { faction in
            Text(faction.rawValue)
        }
    }
    
    var body: some View {
        VStack {
            header
            factionList()
            Spacer()
        }
    }
}

