//
//  SquadXWSImportView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct SquadXWSImportView : View {
    @State private var xws: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    
    var body: some View {
        VStack {
            Text("Squad XWS Import")
                .font(.title)
            
            TextView(text: $xws)
                .frame(numLines: 20)
                .border(Color.gray, width: 2)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            
//            TextField("XWS Import", text: $xws)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(width: 800, height: 400)
//                .border(Color.gray, width: 4)
                
            
            Button(action: {
                self.viewFactory.viewType = .squadViewNew(self.xws)
            } ) {
                Text("Import")
            }
        }
    }
}
