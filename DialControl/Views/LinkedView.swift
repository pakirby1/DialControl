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
import Combine

enum StatButtonType {
    case force
    case shield
    case charge
    case hull
    
    var color: Color {
        get {
            switch(self) {
            case .force: return Color.purple
            case .shield: return Color.blue
            case .charge: return Color.orange
            case .hull: return Color.yellow
            }
        }
    }
    
    var symbol: String {
        get {
            switch(self) {
            case .force: return "h"
            case .shield: return "*"
            case .charge: return "g"
            case .hull: return "&"
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
    let id = UUID()
    var deallocPrinter: DeallocPrinter
    var activeCount: Int
    var inactiveCount: Int
    let maxCount: Int
    let type: StatButtonType
    let symbolSize: CGFloat = 72
    let callback: (Int, Int) -> ()
        
    init(maxCount: Int, type: StatButtonType, callback: @escaping (Int, Int) -> ()) {
        deallocPrinter = DeallocPrinter("LinkedView \(id): \(type) maxCount:\(maxCount)")
        self.maxCount = maxCount
        activeCount = maxCount
        inactiveCount = 0
        self.callback = callback
        self.type = type
    }
    
    init(type: StatButtonType, active: Int, inactive: Int, callback: @escaping (Int, Int) -> ()) {
        deallocPrinter = DeallocPrinter("LinkedView \(id): \(type) active: \(active) inactive: \(inactive)")
        self.maxCount = active + inactive
        self.activeCount = active
        self.inactiveCount = inactive
        self.callback = callback
        self.type = type
    }
    
    // MARK: - Create Tokens (DEPRECATED)
    func createTokenView(symbol: String, color: Color, isActive: Bool) -> AnyView {
        AnyView(
            ZStack {
                Image(uiImage: UIImage(named: "Token.Shape") ?? UIImage())
                    .resizable()
                    .frame(width: 90, height: 90)
                    .foregroundColor(Color.black)
                
                if (isActive) {
                    Image(uiImage: UIImage(named: "Token.Lines") ?? UIImage())
                        .resizable()
                        .frame(width: 96, height: 96)   // Let the lines just barely overlap shape
                        .foregroundColor(color)
                }
                
                Text(symbol)
                    .font(.custom("xwing-miniatures", size: 48))
                    .foregroundColor(color)
            }
        )
    }
    
    func chargeToken(color: Color, isActive: Bool = true) -> AnyView {
        return createTokenView(symbol: StatButtonType.charge.symbol,
                               color: color,
                               isActive: isActive)
    }
    
    func forceToken(color: Color, isActive: Bool = true) -> AnyView {
        return createTokenView(symbol: StatButtonType.force.symbol,
                               color: color,
                               isActive: isActive)
    }
    
    func shieldToken(color: Color, isActive: Bool = true) -> AnyView {
        return createTokenView(symbol: StatButtonType.shield.symbol,
                               color: color,
                               isActive: isActive)
    }
    
    func hullToken(color: Color, isActive: Bool = true) -> AnyView {
        return createTokenView(symbol: StatButtonType.hull.symbol,
                               color: color,
                               isActive: isActive)
    }
    
    func buildTokenView(isActive: Bool) -> some View {
        ZStack {
            if type == .charge {
                chargeToken(color: type.color, isActive: isActive)
            } else if type == .force {
                forceToken(color: type.color, isActive: isActive)
            } else if type == .shield {
                shieldToken(color: type.color, isActive: isActive)
            } else {
                hullToken(color: type.color, isActive: isActive)
            }
        }
    }
    
    var activeButton: some View {
        func action() {
            let active = min(self.activeCount - 1, self.maxCount)
            let inactive = min(self.inactiveCount + 1, self.maxCount)
            self.setState(active: active, inactive: inactive)
        }
        
        return Button(action:action)
        {
            buildTokenView(isActive: true)
        }.overlay(CountBannerView(count: self.activeCount, type: .active)
            .offset(x: CGFloat(50.0),
                    y: CGFloat(-50)))
    }

    var inActiveButton: some View {
        func action() {
            let active = min(self.activeCount + 1, self.maxCount)
            let inactive = min(self.inactiveCount - 1, self.maxCount)
            self.setState(active: active, inactive: inactive)
        }
        
        return Button(action:action)
        {
            buildTokenView(isActive: false)
        }.overlay(CountBannerView(count: self.inactiveCount, type: .inactive).offset(x: 50, y: -50))
    }
    
    func setState(active: Int, inactive: Int) {
        //        self.activeCount = active < 0 ? 0 : active
        //        self.inactiveCount = inactive < 0 ? 0 : inactive
        let activeCount = active < 0 ? 0 : active
        let inactiveCount = inactive < 0 ? 0 : inactive
        
        // Update the PilotStateData
        //        self.callback(self.activeCount, self.inactiveCount)
        self.callback(activeCount, inactiveCount)
    }
    
    // MARK: Create Tokens (DEPRECATED) -
    
    var body: some View {
        HStack(spacing: 25) {
            activeButton
            inActiveButton
        }
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
    let width:CGFloat  = 40
    let height:CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(type.color)
                .frame(width: width, height: height)
            
            Text("\(count)")
                .font(.system(size: 24.0, weight: .bold))
                .foregroundColor(Color.white)
        }
    }
}
