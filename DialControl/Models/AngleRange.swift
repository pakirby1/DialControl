//
//  AngleRange.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct AngleRange : Identifiable, CustomStringConvertible {
    let id: UUID = UUID()
    let start: CGFloat
    let end: CGFloat
    let mid: CGFloat
    let sector: UInt
    
    var description: String {
        return "\(start) \(mid) \(end) \(sector)"
    }
}
