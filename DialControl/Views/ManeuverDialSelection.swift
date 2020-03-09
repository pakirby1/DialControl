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
    
    var body: some View {
        VStack {
            Text(maneuver.bearing.getSymbolCharacter())
                .font(.custom("xwing-miniatures", size: size))
                .foregroundColor(maneuver.difficulty.color())
                .padding(10)
            
            Text("\(maneuver.speed)")
                .font(.custom("KimberleyBl-Regular", size: size))
                .foregroundColor(maneuver.difficulty.color())
        }
        .border(Color.white)
    }
    
    var description: String {
        return "\(maneuver.speed)\(maneuver.bearing.rawValue)"
    }
}
