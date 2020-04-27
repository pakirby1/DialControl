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
    @EnvironmentObject var textViewObserver: TextViewObservable
    let lineHeight = UIFont.systemFont(ofSize: 17).lineHeight
    
    var body: some View {
        VStack {
            Text("Squad XWS Import")
                .font(.title)
            
            TextView(placeholderText: "Squad XWS", text: $xws)
                .padding(10)
                .frame(height: self.textViewObserver.height < 150 ? 150 : self.textViewObserver.height + lineHeight)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 1))
                .environmentObject(textViewObserver)
            
            Button(action: {
                self.viewFactory.viewType = .squadViewNew(self.xws)
            } ) {
                Text("Import")
            }
        }.padding(10)
    }
}

public struct CustomStyle : TextFieldStyle {
  public func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(7)
      .background(
        RoundedRectangle(cornerRadius: 15)
          .strokeBorder(Color.black, lineWidth: 5)
    )
  }
}
