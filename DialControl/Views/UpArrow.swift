//
//  UpArrow.swift
//  DialControl
//
//  Created by Phil Kirby on 3/12/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct UpArrow : Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let top = CGPoint(x: width / 2, y: 0)
        let left = CGPoint(x: 0, y: height / 3)
        let headLeft = CGPoint(x: width / 3, y: height / 3)
        let bottomLeft = CGPoint(x: width / 3, y: height)
        let bottomRight = CGPoint(x: width * 2 / 3, y: height)
        let headRight = CGPoint(x: width * 2 / 3, y: height / 3)
        let right = CGPoint(x: width, y: height / 3)
        
        path.move(to: top)
        path.addLine(to: left)
        path.addLine(to: headLeft)
        path.addLine(to: bottomLeft)
        path.addLine(to: bottomRight)
        path.addLine(to: headRight)
        path.addLine(to: right)
        path.addLine(to: top)
        
        return path
    }
}

struct UpArrowView: View {
    let color: Color
    
    var body: some View {
        UpArrow().fill(color).border(Color.white)
    }
}
