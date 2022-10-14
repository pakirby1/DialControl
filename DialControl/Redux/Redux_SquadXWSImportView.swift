//
//  SquadXWSImportView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData


class Redux_SquadXWSImportViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    let moc: NSManagedObjectContext
    let squadService: SquadServiceProtocol
    let pilotStateService: PilotStateServiceProtocol
    
    init(moc: NSManagedObjectContext,
         squadService: SquadServiceProtocol,
         pilotStateService: PilotStateServiceProtocol)
    {
        self.moc = moc
        self.squadService = squadService
        self.pilotStateService = pilotStateService
    }
}

struct Redux_SquadXWSImportView : View {
    @State private var xws: String = ""
    @State var showAlert: Bool = false
    @State var alertText: String = ""
    
    @EnvironmentObject var store: MyAppStore
    @EnvironmentObject var viewFactory: ViewFactory
    
    let textViewObserver: TextViewObservable = TextViewObservable()
    let lineHeight = UIFont.systemFont(ofSize: 17).lineHeight
    
    func navigateBack() {
        self.viewFactory.back()
    }
    
    var body: some View {
        VStack {
            HStack {
                BackButtonView().environmentObject(viewFactory)
                
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
                self.store.send(.xwsImport(action: .importXWS(self.xws)))
            } ) {
                Text("Import")
            }
        }.padding(10)
            .alert(isPresented: $store.state.xwsImport.showAlert) {
            Alert(title: Text("Alert"),
                  message: Text(store.state.xwsImport.alertText),
                  dismissButton: .default(Text("OK")))
        }
    }
}

