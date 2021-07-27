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
    @State var state: ProgressControlState = .active
    
    var header: some View {
        HStack {
            BackButtonView().environmentObject(viewFactory)
            
            Spacer()
        }.padding(10)
    }
    
    func toolsList() -> some View {
        ForEach(tools, id:\.self) { tool in
            ToolsCardNew(tool: tool) {
                ProgressControl(size: 70,
                                onStart: self.downloadAllImages,
                                onStop: self.cancel)
            }.environmentObject(store)
        }
    }
    
    func displayDeleteConfirmation() {
        self.displayDeleteAllConfirmation = true
    }

    func downloadAllImages() {
        self.store.send(.tools(action: .downloadAllImages))
    }
    
    func cancel() {
        self.store.cancel()
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
    
    var downloadAllImagesCard : some View {
        let tool = Tool(title: "Download All Images",
                        action: downloadAllImages,
                        displayStatus: true)
        func buildProgressControl_Old() -> some View {
            ProgressControl(size: 60,
                            onStart: self.downloadAllImages,
                            onStop: self.cancel)
//                .border(Color.white, width: 1)
                .environmentObject(store)
        }
        
        func buildProgressControl_New() -> some View {
            ProgressControl(size: 60,
                            onStart: self.downloadAllImages,
                            onStop: self.cancel)
//                .border(Color.white, width: 1)
                .environmentObject(store)
        }
        
        return ToolsCardNew(tool: tool) {
            if FeaturesManager.shared.isFeatureEnabled(.DownloadAllImages)
            {
                buildProgressControl_New()
            } else {
                buildProgressControl_Old()
            }
        }
    }
    
    var body: some View {
        VStack {
            header
            ToolsCard(tool: Tool(title: "Delete Image Cache", action: {}))
            downloadAllImagesCard
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
    let statusMessage: String
    
    init(title: String,
         titleColor: Color = WestworldUITheme().TEXT_FOREGROUND,
         action: @escaping () -> Void,
         displayStatus: Bool = false,
         statusMessage: String = "")
    {
        self.title = title
        self.titleColor = titleColor
        self.action = action
        self.displayStatus = displayStatus
        self.statusMessage = statusMessage
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

struct CustomView <Content: View>: View {
    
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    
    var body: some View {

            content()  // <<: Do anything you want with your imported View here.

    }
}

/// Displays a tool card view with a generic accessory view
///
/// - Parameter AccessoryView: Generic type constraint. used by the `@ViewBuilder`
///   closure input parameter
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
    var content: () -> AccessoryView
    
    /// - Parameter tool: Model object
    /// - Parameter content: closure that returns an `AccessoryView` generic type
    ///
    /// `ToolsCardView(tool: greetingTool) {`
    /// `     Image(named: 'greetingPic')  `
    /// ` } `
    init(tool: Tool, @ViewBuilder content: @escaping () -> AccessoryView) {
        self.content = content
        self.tool = tool
    }
    
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
    
    var statusView_Old: some View {
        var message: String = ""
        
        if (self.store.state.tools.message.count > 0) {
            message = self.store.state.tools.message
        } else {
            message = self.store.state.tools.downloadImageEvent?.file ?? ""
        }
        
        return Text(message)
            .font(.headline)
            .foregroundColor(self.tool.titleColor)
    }
    
    var statusView_New: AnyView {
        return VStack {
            Button(action: {
                    self
                        .store
                        .send(MyAppAction.tools(action: .downloadAllImages))
            })
            {
                Text("Download All Images")
                    .font(.largeTitle)
            }
            
            Text(self.store.state.tools.currentImage.description)
        }.eraseToAnyView()
    }
    
    var body: some View {
        Button(action: self.tool.action)
        {
            ZStack {
                background
                VStack {
                    if (tool.displayStatus) {
                        if FeaturesManager.shared.isFeatureEnabled(.DownloadAllImages)
                        {
                            statusView_New
                        } else {
                            statusView_Old
                        }
                    }
                }
                self.content().offset(x: 300, y: 0)
            }
        }
    }
}
