//
//  ResetButton.swift
//  DialControl
//
//  Created by Phil Kirby on 2/19/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct ResetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            self.action()
        })
        {
            HStack {
                Text("Reset")
                    .foregroundColor(.white)
                
                Image(uiImage: UIImage(named: "Reset") ?? UIImage())
                
//                Image(systemName: "repeat")
//                    .font(.largeTitle)
//                    .foregroundColor(.accentColor)
            }
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
