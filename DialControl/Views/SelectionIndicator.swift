//
//  SelectionIndicator.swift
//  DialControl
//
//  Created by Phil Kirby on 4/4/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectionIndicator : Shape {
    let sectorAngle: Double
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center =  CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let halfSectorAngle: Double = (sectorAngle / 2)
        let leftAngle: Angle = .degrees(270 - halfSectorAngle)
        let rightAngle: Angle = .degrees(270 + halfSectorAngle)
        let innerRadius = radius / 2.75
        let outerRadius = radius - 20
        
        p.addArc(center: center,
                 radius: innerRadius,
                 startAngle: leftAngle,
                 endAngle: rightAngle,
                 clockwise: true)
        
        p.addArc(center: center,
                 radius: outerRadius,
                 startAngle: rightAngle,
                 endAngle: leftAngle,
                 clockwise: false)
        
        p.closeSubpath()
        
        return p
    }
}
