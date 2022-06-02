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


// Popover
// https://www.vadimbulavin.com/swiftui-popup-sheet-popover/
/*
 .popup(isPresented: isTopSnackbarPresented, alignment: .top, direction: .top, content: Snackbar.init)
 .popup(isPresented: isLoaderPresented, alignment: .center, content: Loader.init)
 */
struct Popup<T: View>: ViewModifier {
    let popup: T
    let alignment: Alignment
    let direction: Direction
    let isPresented: Bool

    init(isPresented: Bool,
         alignment: Alignment,
         direction: Direction,
         @ViewBuilder content: () -> T)
    {
        self.isPresented = isPresented
        self.alignment = alignment
        self.direction = direction
        popup = content()
    }

    func body(content: Content) -> some View {
        content
            .overlay(popupContent())
    }

    @ViewBuilder
    private func popupContent() -> some View {
        GeometryReader { geometry in
            if isPresented {
                popup
//                    .animation(.spring())
//                    .transition(.offset(x: 0, y: direction.offset(popupFrame: geometry.frame(in: .global))))
                    .frame(width: geometry.size.width,
                           height: geometry.size.height,
                           alignment: alignment)
            }
        }
    }
}

extension Popup {
    enum Direction {
        case top, bottom

        func offset(popupFrame: CGRect) -> CGFloat {
            switch self {
            case .top:
                let aboveScreenEdge = -popupFrame.maxY
                return aboveScreenEdge
            case .bottom:
                let belowScreenEdge = UIScreen.main.bounds.height - popupFrame.minY
                return belowScreenEdge
            }
        }
    }
}



private extension View {
    func onGlobalFrameChange(_ onChange: @escaping (CGRect) -> Void) -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(key: FramePreferenceKey.self, value: geometry.frame(in: .global))
        })
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }

    func print(_ varargs: Any...) -> Self {
        Swift.print(varargs)
        return self
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}




