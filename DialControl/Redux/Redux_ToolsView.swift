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
    
    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.back()
            }) {
                Text("< Back")
            }
            
            Spacer()
        }.padding(10)
    }
    
    func toolsList() -> some View {
        ForEach(tools, id:\.self) { tool in
            ToolsCard(tool: tool)
        }
    }
    
    func buildTools() {
        self.tools.append(Tool(title: "Delete Image Cache", action: {}))
        
        self.tools.append(Tool(title: "Download All Images", action: {}))
        
        self.tools.append(Tool(title: "Delete All Squads", action: { self.store.send(.faction(action: .deleteAllSquads)) }))
    }
    
    var body: some View {
        VStack {
            header
            toolsList()
            Spacer()
        }.onAppear(perform: buildTools)
    }
}

struct Tool : Hashable {
    let title: String
    let action: () -> Void
    
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
                .foregroundColor(viewModel.textForeground)
        }
    }
    
    var body: some View {
        Button(action: self.tool.action)
        {
            ZStack {
                background
                titleView
            }
        }
    }
}
