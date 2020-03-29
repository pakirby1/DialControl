//
//  PathNode.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct PathNodeStruct<T: View> : Identifiable {
    var id: UUID = UUID()
    
    let view: T
    let rotationAngle: Angle
    let offset: (CGFloat, CGFloat)
    let sectorAngle: Angle // angle of entire sector
}
