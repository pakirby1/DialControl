//
//  CustomDivider.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct CustomDivider: View {
    let color: Color = .white
    let width: CGFloat = 2
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.5))
            .frame(height: width)
//            .edgesIgnoringSafeArea(.horizontal)
    }
}
