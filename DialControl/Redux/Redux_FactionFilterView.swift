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
    @State var test: Bool = false
    @EnvironmentObject var store: MyAppStore

    var header: some View {
        HStack {
            BackButtonView().environmentObject(viewFactory)
            
            Spacer()
            
            Text(self.store.state.factionFilter.selectedFaction.rawValue)
                .font(.largeTitle)
            
            Spacer()
            Spacer()
            
        }.padding(10)
    }
    
    func factionList() -> some View {
        return List(Faction.allCases, id:\.self) { faction in
            FactionFilterRow(faction: faction,
                             selectedFaction: store.state.factionFilter.selectedFaction
                             ) { faction in
                store.send(MyAppAction.factionFilter(action: .selectFaction(faction)))
            }
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
    let selectedFaction: Faction
    let symbolSize: CGFloat = 72.0
    let callBack: (Faction) -> Void
    
    var body: some View {
        HStack {
            Text(faction.characterCode)
                .font(.custom("xwing-miniatures", size: self.symbolSize))
            
            Text(faction.rawValue).font(.largeTitle)
            
            if (faction == selectedFaction) {
                Image(systemName: "checkmark")
            }
            
        }.onTapGesture{
            print("Tapped \(faction.rawValue)")
            self.callBack(faction)
        }
    }
}


