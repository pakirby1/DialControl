//
//  BackButtonView.swift
//  DialControl
//
//  Created by Phil Kirby on 5/14/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct BackButtonView : View {
    @EnvironmentObject var viewFactory: ViewFactory
    
    var body: some View {
        Button(action: { self.viewFactory.back() }) {
            Image(systemName: "chevron.backward.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 48, weight: .bold))
        }
    }
}
