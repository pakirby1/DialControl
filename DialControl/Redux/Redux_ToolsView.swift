//
//  Redux_ToolsView.swift
//  DialControl
//
//  Created by Phil Kirby on 5/12/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct Redux_ToolsView: View {
    @EnvironmentObject var viewFactory: ViewFactory
    @State var tools: [Tool] = []
    @EnvironmentObject var store: MyAppStore
    @State var displayDeleteAllConfirmation: Bool = false
    
    var header: some View {
        HStack {
            BackButtonView().environmentObject(viewFactory)
            
            Spacer()
        }.padding(10)
    }
    
    func toolsList() -> some View {
        ForEach(tools, id:\.self) { tool in
            ToolsCard(tool: tool).environmentObject(store)
        }
    }
    
    func displayDeleteConfirmation() {
//        if self.store.state.faction.squadDataList.count > 0 {
            self.displayDeleteAllConfirmation = true
//        }
    }

    func downloadAllImages() {
        self.store.send(.tools(action: .downloadAllImages))
    }
    
    func buildTools() {
        self.tools.append(Tool(title: "Delete Image Cache", action: {}))
        
        self.tools.append(Tool(title: "Download All Images", action: downloadAllImages, displayStatus: true))
        
        self.tools.append(Tool(title: "Delete All Squads",
                               titleColor: Color.red,
                               action: displayDeleteConfirmation)
        )
    }
    
    var deleteAllAlertAction: () -> Void {
        get {
            return { self.store.send(.faction(action: .deleteAllSquads)) }
        }
    }
    
    var cancelAlertAction: () -> Void {
        get {
            return self.cancelAction(title: "Delete") {
                self.displayDeleteAllConfirmation = false
            }
        }
    }
    
    func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void {
        return {
            print("Cancelled \(title)")
            callback()
        }
    }
    
    var body: some View {
        VStack {
            header
//            toolsList()
            ToolsCard(tool: Tool(title: "Delete Image Cache", action: {}))
            ToolsCard(tool: Tool(title: "Download All Images", action: downloadAllImages, displayStatus: true))
            ToolsCard(tool: Tool(title: "Delete All Squads",
                                 titleColor: Color.red,
                                 action: displayDeleteConfirmation))
            Spacer()
        }.onAppear(perform: buildTools)
        .alert(isPresented: $displayDeleteAllConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("All Squads?"),
                primaryButton: Alert.Button.default(Text("Delete"), action: deleteAllAlertAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: cancelAlertAction)
            )
        }
    }
}

struct Tool : Hashable {
    let title: String
    let action: () -> Void
    let titleColor: Color
    let displayStatus: Bool
    
    init(title: String,
         titleColor: Color = WestworldUITheme().TEXT_FOREGROUND,
         action: @escaping () -> Void,
         displayStatus: Bool = false)
    {
        self.title = title
        self.titleColor = titleColor
        self.action = action
        self.displayStatus = displayStatus
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
    static func == (lhs: Tool, rhs: Tool) -> Bool {
        lhs.title == rhs.title
    }
}

struct ToolsCard: View {
    struct ToolsCardViewModel {
        let theme: Theme = WestworldUITheme()
        let symbolSize: CGFloat = 36.0
        
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
    @EnvironmentObject var store: MyAppStore
    let tool: Tool
    let viewModel = ToolsCardViewModel()
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var titleView: some View {
        HStack {
            Text(self.tool.title)
                .font(.title)
                .foregroundColor(self.tool.titleColor)
        }
    }
    
    var statusView: some View {
        Text(self.store.state.tools.downloadImageEvent?.file ?? "")
            .font(.headline)
            .foregroundColor(self.tool.titleColor)
    }
    
    var body: some View {
        Button(action: self.tool.action)
        {
            ZStack {
                background
                VStack {
                    titleView
                    
                    if (tool.displayStatus) {
                        statusView
                    }
                }
            }
        }
    }
}

struct ToolsCardNew<AccessoryView: View>: View {
    struct ToolsCardViewModel {
        let theme: Theme = WestworldUITheme()
        let symbolSize: CGFloat = 36.0
        
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
    
    @EnvironmentObject var store: MyAppStore
    let tool: Tool
    let viewModel = ToolsCardViewModel()
    let accessoryView: AccessoryView?
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var titleView: some View {
        HStack {
            Text(self.tool.title)
                .font(.title)
                .foregroundColor(self.tool.titleColor)
        }
    }
    
    var statusView: some View {
        Text(self.store.state.tools.downloadImageEvent?.file ?? "")
            .font(.headline)
            .foregroundColor(self.tool.titleColor)
    }
    
    var body: some View {
        Button(action: self.tool.action)
        {
            ZStack {
                background
                VStack {
                    titleView
                    
                    if (tool.displayStatus) {
                        statusView
                    }
                }
                accessoryView.offset(x: 50, y: 0)
            }
        }
    }
}
