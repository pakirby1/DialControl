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
    case LT
    case LB
    case S
    case RB
    case RT
    case LTA
    case RTA
    case K
    case LS
    case RS
    case X
    
    func getSymbolCharacter() -> String {
        switch(self) {
        case .LT:
            return "4"
        case .LB:
            return "7"
        case .S:
            return "8"
        case .RB:
            return "9"
        case .RT:
            return "6"
        case .RTA:
            return ";"
        case .LTA:
            return ":"
        case .K:
            return "2"
        case .LS:
            return "1"
        case .RS:
            return "3"
        case .X:
            return "5"
        }
    }
}

enum ManeuverDifficulty {
    
    case Red
    case White
    case Blue
    
    func color() -> Color {
        switch(self) {
        case .Red:
            return Color.red
        case .White:
            return Color.white
        case .Blue:
            return Color.blue
        }
    }
}

struct Maneuver: CustomStringConvertible {
    let speed: UInt
    let bearing: ManeuverBearing
    let difficulty: ManeuverDifficulty
    
    var description: String {
        return "\(speed)\(bearing.rawValue)"
    }
}
