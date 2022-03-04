//
//  ResetButton.swift
//  DialControl
//
//  Created by Phil Kirby on 2/19/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct VectorImageButton: View {
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            self.action()
        })
        {
            HStack {
                Image(uiImage: UIImage(named: imageName) ?? UIImage())
                    .resizable()
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    .frame(width: 60, height: 60, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    
            }
            .padding(5)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
