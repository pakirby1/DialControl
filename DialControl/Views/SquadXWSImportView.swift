//
//  SquadXWSImportView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

class SquadXWSImportViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    
    func loadSquad(jsonString: String) -> Squad {
        return Squad.serializeJSON(jsonString: jsonString) { errorString in
            self.alertText = errorString
            self.showAlert = true
        }
    }
}

struct SquadXWSImportView : View {
    @State private var xws: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var textViewObserver: TextViewObservable
    let lineHeight = UIFont.systemFont(ofSize: 17).lineHeight
    @State var showAlert: Bool = false
    @State var alertText: String = ""
    @ObservedObject var viewModel: SquadXWSImportViewModel = SquadXWSImportViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
                }) {
                    Text("< Faction Squad List")
                }
                
                Spacer()
            }
            
            Text("Squad XWS Import")
                .font(.title)
            
            TextView(placeholderText: "Squad XWS", text: $xws)
                .padding(10)
                .frame(height: self.textViewObserver.height < 600 ? 600 : self.textViewObserver.height + lineHeight)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.blue, lineWidth: 1))
                .environmentObject(textViewObserver)
            
            Button(action: {
                let squad = self.viewModel.loadSquad(jsonString: self.xws)
                
                if squad.name != Squad.emptySquad.name {
                    self.viewFactory.viewType = .factionSquadList(.galactic_empire)
                }
            } ) {
                Text("Import")
            }
        }.padding(10)
            .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.alertText),
                  dismissButton: .default(Text("OK")))
        }
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
