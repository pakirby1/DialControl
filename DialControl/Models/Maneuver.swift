//
//  Maneuver.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

enum ManeuverBearing : String {
    case E      // Left Talon
    case L      // Left Sloop
    case T      // Left Turn
    case B      // Left Bank
    case A      // Left Reverse
    case O      // Stop
    case S      // Reverse
    case F      // Forward
    case R      // Right Talon
    case P      // Right Sloop
    case Y      // Right Turn
    case N      // Right Bank
    case D      // Right Reverse
    case K      // K Turn
    
    func getSymbolCharacter() -> String {
        switch(self) {
        case .E: // Left Talon
            return ":"
        case .L: // Left Sloop
            return "1"
        case .T: // Left Turn
            return "4"
        case .B: // Left Bank
            return "7"
        case .A: // Left Reverse
            return "J"
        case .O: // Stop
            return "5"
        case .S: // Reverse
            return "K"
        case .F: // Forward
            return "8"
        case .R: // Right Talon
            return ";"
        case .P: // Right Sloop
            return "3"
        case .Y: // Right Turn
            return "6"
        case .N: // Right Bank
            return "9"
        case .D: // Right Reverse
            return "L"
        case .K: // K Turn
            return "2"
        }
    }
}

enum ManeuverDifficulty: String {
    case R
    case W
    case B
    case P
    
    var color : Color {
        switch(self) {
        case .R:
            return Color.red
        case .W:
            return Color.white
        case .B:
            return Color.blue
        case .P:
            return Color.purple
        }
    }
}

struct Maneuver: CustomStringConvertible {
    let speed: UInt
    let bearing: ManeuverBearing
    let difficulty: ManeuverDifficulty
    
    var description: String {
        return "\(speed)\(bearing.rawValue)\(difficulty.rawValue)"
    }
    
    static func buildManeuver(maneuver: String) -> Maneuver {
        let speed: Character = maneuver[0]
        let b: String = String(maneuver[1])
        let bearing: ManeuverBearing? = ManeuverBearing(rawValue: b)
        let difficulty: ManeuverDifficulty? = ManeuverDifficulty(rawValue: String(maneuver[2]))
        
        // Remove !
        let ret = Maneuver(speed: UInt(String(speed))!,
                           bearing: bearing!,
                           difficulty: difficulty!)

        return ret
    }
    
    var view : AnyView {
        let view = HStack {
            Text("\(speed)")
                .font(.system(size: 30.0, weight: .bold))
                .foregroundColor(difficulty.color)
            
            buildSymbolView()
        }
        
        return AnyView(view)
    }
    
    func buildSymbolView() -> AnyView {
            func buildSFSymbolView() -> AnyView {
                return AnyView(Image(systemName: "arrow.up")
                    .font(.system(size: 30.0, weight: .bold))
                    .foregroundColor(difficulty.color))
            }
            
            func buildArrowView() -> AnyView {
                return AnyView(UpArrowView(color: difficulty.color))
            }
            
            func buildTextFontView(baselineOffset: CGFloat = 0) -> AnyView {
                let symbol = bearing.getSymbolCharacter()
                
                return AnyView(Text(symbol).baselineOffset(baselineOffset)
                    .font(.custom("xwing-miniatures", size: 36))
                    .foregroundColor(difficulty.color)
                    .padding(2))
            }
            
            // For some reason, the top of the arrow gets cut off for the "8" (Straight) bearing in x-wing font. See baselineOffset
            if bearing == .F {
                return AnyView(buildTextFontView(baselineOffset: -10))
            } else if bearing == .K {
                return AnyView(buildTextFontView(baselineOffset: -5))
            } else {
                return AnyView(buildTextFontView())
            }
        }
}
