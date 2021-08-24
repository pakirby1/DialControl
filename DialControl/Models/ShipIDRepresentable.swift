//
//  ShipIDRepresentable.swift
//  DialControl
//
//  Created by Phil Kirby on 8/24/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

protocol ShipIDRepresentable {
    associatedtype V: View
    var shipID: V { get }
    var shipPilot: ShipPilot { get }
}

extension ShipIDRepresentable {
    var shipID: some View {
        func buildNumberView(id: Int) -> some View {
            let name = "\(id).circle"
            return Image(systemName: name)
                .font(.largeTitle)
                .foregroundColor(Color.white)
        }
        
        func buildSmallIndicatorView(color: Color) -> some View {
            return IndicatorView(
                label: " ",
                bgColor: color,
                fgColor: Color.clear).frame(
                    width: 5,
                    height: 5,
                    alignment: .center).padding(20)
        }
        
        @ViewBuilder
        func buildShipIDView() -> some View {
            let id = shipPilot.pilotStateData!.shipID.lowercased().trimmingCharacters(in: .whitespaces)
            
            if let idAsNum: Int = Int(id), idAsNum < 51 {
                buildNumberView(id: idAsNum)
            } else {
                switch(id) {
                    case "red":
                        buildSmallIndicatorView(color: Color.red)
                    case "green":
                        buildSmallIndicatorView(color: Color.green)
                    case "yellow":
                        buildSmallIndicatorView(color: Color.yellow)
                    case "blue":
                        buildSmallIndicatorView(color: Color.blue)
                    case "orange":
                        buildSmallIndicatorView(color: Color.orange)
                    case "purple":
                        buildSmallIndicatorView(color: Color.purple)
                    case "pink":
                        buildSmallIndicatorView(color: Color.pink)
                    case "gray", "grey":
                        buildSmallIndicatorView(color: Color.gray)
                        
                    default:
                        Text(shipPilot.pilotStateData!.shipID).padding(5).foregroundColor(Color.white)
                }
            }
        }
        
        return buildShipIDView()
    }
}

