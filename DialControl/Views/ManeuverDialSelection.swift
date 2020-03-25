//
//  ManeuverDialSelection.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct ManeuverDialSelection: View, CustomStringConvertible {
    let maneuver: Maneuver
    let size: CGFloat
    
    func buildSymbol() -> AnyView {
        func buildUpArrowView() -> AnyView {
            return AnyView(UpArrowView(color: maneuver.difficulty.color)
                .frame(width: 30, height: 30, alignment: .center)
                .border(Color.white, width: 1))
        }
        
        func buildTextFontView(baselineOffset: CGFloat = 0) -> AnyView {
            return AnyView(Text(maneuver.bearing.getSymbolCharacter()).baselineOffset(baselineOffset)
                .font(.custom("xwing-miniatures", size: size))
                .foregroundColor(maneuver.difficulty.color)
                .padding(5))
        }
        
        if maneuver.bearing == .S {
            return buildUpArrowView()
        } else if maneuver.bearing == .F {
            return buildTextFontView(baselineOffset: -10.0)
        } else if maneuver.bearing == .K {
            return buildTextFontView(baselineOffset: -10.0)
        } else {
            return buildTextFontView()
        }
    }
    
    var body: some View {
        VStack {
            buildSymbol()
            
            Text("\(maneuver.speed)")
                .font(.custom("KimberleyBl-Regular", size: size))
                .foregroundColor(maneuver.difficulty.color)
        }
//        .border(Color.white)
    }
    
    var description: String {
        return "\(maneuver.speed)\(maneuver.bearing.rawValue)"
    }
}
