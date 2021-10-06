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
//                        buildSmallIndicatorView(color: Color.red)
                        ShipIDView(fill: Color.red)
                    case "green":
                        ShipIDView(fill:Color.green)
                    case "yellow":
                        ShipIDView(fill:Color.yellow)
                    case "blue":
                        ShipIDView(fill:Color.blue)
                    case "orange":
                        ShipIDView(fill:Color.orange)
                    case "purple":
                        ShipIDView(fill:Color.purple)
                    case "pink":
                        ShipIDView(fill:Color.pink)
                    case "gray", "grey":
                        ShipIDView(fill:Color.gray)
                    case "black":
                        ShipIDView(fill: Color.black, stroke: Color.white)
                        
                    default:
                        Text(shipPilot.pilotStateData!.shipID).padding(5).foregroundColor(Color.white)
                }
            }
        }
        
        return buildShipIDView()
    }
}

