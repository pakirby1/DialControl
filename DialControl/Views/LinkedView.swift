//
//  LinkedView.swift
//  DialControl
//
//  Created by Phil Kirby on 4/6/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct LinkedView: View {
    @State private var activeCount: Int
    @State private var inactiveCount: Int
    let maxCount: Int
    
    init(maxCount: Int) {
        self.maxCount = maxCount
        _activeCount = State(initialValue: maxCount)
        _inactiveCount = State(initialValue: 0)
    }
    
    var body: some View {
        HStack {
            Button(action:{
                let active = min(self.activeCount - 1, self.maxCount)
                let inactive = min(self.inactiveCount + 1, self.maxCount)
                self.setState(active: active, inactive: inactive)
            })
            {
                Text("\(activeCount)")
                    .frame(width: 100, height: 100)
                    .background(Color.purple)
                    .foregroundColor(Color.white)
                    .cornerRadius(20)
            }
            
            Button(action:{
                let active = min(self.activeCount + 1, self.maxCount)
                let inactive = min(self.inactiveCount - 1, self.maxCount)
                self.setState(active: active, inactive: inactive)
            })
            {
                Text("\(inactiveCount)")
                    .frame(width: 100, height: 100)
                    .background(Color.purple)
                    .foregroundColor(Color.white)
                    .cornerRadius(20)
            }
        }
    }
    
    func setState(active: Int, inactive: Int) {
        self.activeCount = active < 0 ? 0 : active
        self.inactiveCount = inactive < 0 ? 0 : inactive
    }
}
