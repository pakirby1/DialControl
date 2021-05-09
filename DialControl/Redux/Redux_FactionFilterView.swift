//
//  Redux_FactionFilterView.swift
//  DialControl
//
//  Created by Phil Kirby on 5/8/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct Redux_FactionFilterView: View {
    @EnvironmentObject var viewFactory: ViewFactory
    let faction: Faction
    
    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.back()
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
            FactionFilterRow(faction: faction)
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

struct FactionFilterRow: View {
    let faction: Faction
    let symbolSize: CGFloat = 72.0
    
    var body: some View {
        HStack {
            Text(faction.characterCode)
                .font(.custom("xwing-miniatures", size: self.symbolSize))
            
            Text(faction.rawValue).font(.largeTitle)
        }
    }
}


