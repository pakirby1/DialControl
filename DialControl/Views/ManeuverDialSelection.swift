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
                .frame(width: 50, height: 50, alignment: .center))
        }
        
        func buildTextFontView() -> AnyView {
            return AnyView(Text(maneuver.bearing.getSymbolCharacter())
                .font(.custom("xwing-miniatures", size: size))
                .foregroundColor(maneuver.difficulty.color)
                .padding(10))
        }
        
        if maneuver.bearing == .S {
            return buildUpArrowView()
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
