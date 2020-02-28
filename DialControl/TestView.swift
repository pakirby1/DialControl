//
//  TestView.swift
//  DialControl
//
//  Created by Phil Kirby on 2/27/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

struct DragView: View {
    var text:String

    @State var dragAmt = CGSize.zero

    var body: some View {
        Text(text)
            .padding(15)
            .background(Color.orange)
            .cornerRadius(20)
            .padding(5)
            .frame(width: 150, height: 60, alignment: .leading)
            .offset(dragAmt)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged {
                        self.dragAmt = CGSize(width: $0.translation.width, height: $0.translation.height)
                }
                .onEnded {_ in
                    self.dragAmt = CGSize.zero
            })
    }
}

struct TestView2: View {
    var body: some View {
        HStack {
            ScrollView {
                VStack {
                    DragView(text: "hi")
                    DragView(text: "hi")
                    DragView(text: "hi")
                }
            }
            Divider()
            VStack {
                DragView(text: "hi")
                DragView(text: "hi")
                DragView(text: "hi")
            }
        }
    }
}
