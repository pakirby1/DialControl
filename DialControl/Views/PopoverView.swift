//
//  PopoverView.swift
//  LeagueManager
//
//  Created by Phil Kirby on 11/25/19.
//  Copyright © 2019 SoftDesk. All rights reserved.
//
import SwiftUI
import Foundation

struct PopoverMenuItem<T> {
    let id: T
    let name: String
    let action: (T) -> ()
    let imageSystemName: String
}

struct PopoverViewModel<T> {
    @Binding var showOverlay: Bool
    let menuItems: [PopoverMenuItem<T>]
    let title: String
}

struct PopoverView<T> : View {
    let viewModel: PopoverViewModel<T>
//    @EnvironmentObject var settings: LeagueSettings
    @Environment(\.theme) var count
    let theme: Theme = WestworldUITheme()
    
    private var backgroundView: some View {
        get {
            // clear colors are untappable, workaround is to use a color with 1/1000th opacity
            // https://stackoverflow.com/questions/58696455/swiftui-ontapgesture-on-color-clear-background-behaves-differently-to-color-blue
            
            return Rectangle()
                .fill(Color.blue.opacity(0.0001))
                .frame(minWidth: 0, maxWidth: .infinity)
                .onTapGesture { self.viewModel.showOverlay = false }
        }
    }
    
    private var headerView: some View {
        get {
            return ZStack {
                RoundedRectangle(cornerRadius: 10.0)
                    .fill(theme.BUTTONBACKGROUND)
                    .frame(width: 300, height: 50)
                
                Text(self.viewModel.title)
                    .font(.title)
            }
        }
    }
    
    private var menuItems: some View {
        get {
            VStack() {
                ForEach(self.viewModel.menuItems, id:\.name) { menuItem in
                    self.buildMenuItem(menuItem)
                }
            }
            .padding(10)
            .background(theme.BUTTONBACKGROUND
                .cornerRadius(10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.BORDER_ACTIVE, lineWidth: 2)
            )
        }
    }
    
    private func buildMenuItem<T>(_ menuItem: PopoverMenuItem<T>) -> some View {
        return HStack {
            Image(systemName: menuItem.imageSystemName).font(.system(size: 18))
            Text(menuItem.name)
        }.frame(width: 275, height: 50)
            .background(theme.BUTTONBACKGROUND)
        .cornerRadius(10.0)
        .onTapGesture { menuItem.action(menuItem.id) }
    }
    
    var body: some View {
        ZStack {
            // bottom layer
            backgroundView
            
            // popover layer
            VStack {
                headerView
                menuItems
            }
        }
    }
}

struct ThemeKey: EnvironmentKey {
    static var defaultValue: Int = 10
}

extension EnvironmentValues {
    var theme: Int {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

