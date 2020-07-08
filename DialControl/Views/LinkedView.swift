//
//  LinkedView.swift
//  DialControl
//
//  Linked button views on ShipView
//  Created by Phil Kirby on 4/6/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

enum StatButtonType {
    case force
    case shield
    case charge
    
    var color: Color {
        get {
            switch(self) {
            case .force: return Color.purple
            case .shield: return Color.blue
            case .charge: return Color.yellow
            }
        }
    }
    
    var symbol: String {
        get {
            switch(self) {
            case .force: return "h"
            case .shield: return "*"
            case .charge: return "g"
            }
        }
    }
}

enum StatButtonState {
    case active
    case inactive
    
    var color: Color {
        get {
            switch(self) {
            case .active: return Color.white
            case .inactive: return Color.red
            }
        }
    }
}

struct LinkedView: View {
    @State private var activeCount: Int
    @State private var inactiveCount: Int
    let maxCount: Int
    let type: StatButtonType
    let symbolSize: CGFloat = 72
    
    init(maxCount: Int, type: StatButtonType) {
        self.maxCount = maxCount
        _activeCount = State(initialValue: maxCount)
        _inactiveCount = State(initialValue: 0)
        self.type = type
    }
    
    var body: some View {
        HStack(spacing: 25) {
            Button(action:{
                let active = min(self.activeCount - 1, self.maxCount)
                let inactive = min(self.inactiveCount + 1, self.maxCount)
                self.setState(active: active, inactive: inactive)
            })
            {
                ZStack {
                    Color.black
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    if type == .charge {
                        Text("g")
                            .font(.custom("xwing-miniatures", size: symbolSize))
                            .frame(width: 75, height: 75)
                            .foregroundColor(type.color)
                            .offset(x: 6, y: 0)
                    } else {
                        Text("\(type.symbol)")
                            .font(.custom("xwing-miniatures", size: symbolSize))
                            .frame(width: 100, height: 100)
                            .foregroundColor(type.color)
                            .cornerRadius(20)
//                            .border(Color.green, width: 2)
                    }
                }
            }.overlay(CountBannerView(count: self.activeCount, type: .active).offset(x: 50, y: -50))
            
            Button(action:{
                let active = min(self.activeCount + 1, self.maxCount)
                let inactive = min(self.inactiveCount - 1, self.maxCount)
                self.setState(active: active, inactive: inactive)
            })
            {
                ZStack {
                    Color.black
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    if type == .charge {
                        Text("g")
                            .font(.custom("xwing-miniatures", size: symbolSize))
                            .frame(width: 75, height: 75)
                            .foregroundColor(StatButtonState.inactive.color)
                            .offset(x: 6, y: 0)
                    } else {
                        Text("\(type.symbol)")
                            .font(.custom("xwing-miniatures", size: symbolSize))
                            .frame(width: 100, height: 100)
                            .foregroundColor(StatButtonState.inactive.color)
                            .cornerRadius(20)
//                            .border(Color.green, width: 2)
                    }
                }
            }.overlay(CountBannerView(count: self.inactiveCount, type: .inactive).offset(x: 50, y: -50))
        }
    }
    
    func setState(active: Int, inactive: Int) {
        self.activeCount = active < 0 ? 0 : active
        self.inactiveCount = inactive < 0 ? 0 : inactive
    }
}

enum CountBannerType {
    case active
    case inactive
    
    var color: Color {
        get {
            switch(self) {
            case .active: return Color.green
            case .inactive: return Color.red
            }
        }
    }
}

struct CountBannerView: View {
    let count: Int
    let type: CountBannerType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(type.color)
                .frame(width: 40, height: 40)
            
            Text("\(count)")
                .font(.system(size: 24.0, weight: .bold))
                .foregroundColor(Color.white)
        }
    }
}
