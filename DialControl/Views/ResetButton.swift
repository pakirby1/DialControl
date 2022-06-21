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
    let size: CGSize
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            self.action()
        })
        {
            HStack {
                Image(uiImage: UIImage(named: imageName) ?? UIImage())
                    .resizable()
                    .frame(width: size.width, height: size.height, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.red)
            }
            .padding(5)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
