//
//  HealthStat.swift
//  DialControl
//
//  Created by Phil Kirby on 3/24/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct HealthStat : Identifiable {
    let id = UUID()
    let type: StatButtonType
    let value: Int
//
//    var image: Image {
//        return UIImage(type.text)
//    }
}
