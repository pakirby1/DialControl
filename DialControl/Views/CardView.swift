//
//  CardView.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct CardViewModel {
    let strokeColor: Color
    let strokeWidth: CGFloat
    let backgroundColor: Color
    let headerText: String
    let headerBackgroundColor: Color
    let headerTextColor: Color
    let cornerRadius: CGFloat
}

struct CardView<Content: View>: View {
    let cardViewModel: CardViewModel
    let content: () -> Content
    
    init(cardViewModel: CardViewModel,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.cardViewModel = cardViewModel
        self.content = content
    }
        
    var cardView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: cardViewModel.cornerRadius, style: .continuous)
                .fill(cardViewModel.backgroundColor)

            VStack {
                HStack {
                    Spacer()
                
                    Text("\(cardViewModel.headerText)")
                        .font(.title)
                        .foregroundColor(cardViewModel.headerTextColor)
                    
                    Spacer()
                }.background(cardViewModel.headerBackgroundColor)
                
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: cardViewModel.cornerRadius, style: .continuous))
            .multilineTextAlignment(.center)
        }
    }
    
    var body: some View {
        cardView.overlay(
            RoundedRectangle(cornerRadius: cardViewModel.cornerRadius)
                .stroke(cardViewModel.strokeColor, lineWidth: cardViewModel.strokeWidth)
        )
    }
}

