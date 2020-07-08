//
//  UpArrow.swift
//  DialControl
//
//  Created by Phil Kirby on 3/12/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct UpArrowView: View {
    let color: Color
    
    var body: some View {
        UpArrow()
            .fill(color)
            .padding(2)
//            .border(Color.white)
    }
}
