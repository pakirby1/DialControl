//
//  HealthStatsView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/24/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct HealthStatsView: View {
    let healthStats: [HealthStat]
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(healthStats) { stat in
                HealthStatView(stat: stat)
            }
        }.padding(5)
    }
}

struct HealthStatView: View {
    let stat: HealthStat
    
    var body: some View {
        HStack {
            Text("\(stat.value)")
                .font(.title)
                .bold()
                .foregroundColor(stat.type.color)
            
            Text(stat.type.symbol)
//                .baselineOffset(baselineOffset)
                .font(.custom("xwing-miniatures", size: 24))
                .foregroundColor(stat.type.color)
//                .padding(2)
        }
    }
}
