//
//  ProgressControl.swift
//  DialControl
//
//  Created by Phil Kirby on 6/23/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import CoreData
import Combine
import SwiftUI

enum ProgressControlState {
    /*
     DownloadEventEnum
     
     case idle
     case inProgress(DownloadEvent)
     case finished
     case failed(Error)
     case cancelled
     */
    
    case idle   // idle
    case active // inProgress(DownloadEvent)
    case paused // ???
    case cancelled // cancelled, failed
    case completed // finished
    
    mutating func handleEvent(event: ProgressControlEvent,
                              onStart: ()->(),
                              onStop: ()->())
    {
        print("controlImage current: \(self) event: \(event)")
        
        switch(self, event) {
            case (.idle, .tap) :
                self = .active
                onStart()
                
            case (.active, .tap) :
                self = .paused
                onStop()
                
            case (.paused, .tap) :
                self = .active
                onStart()
                
            case (.cancelled, .tap) :
                self = .idle
                onStop()
                
            case (.completed, .tap) :
                self = .active
                onStart()
                
            case (.active, .doubleTap) :
                self = .cancelled
                onStop()
                
            case (.cancelled, .doubleTap):
                return
            case (.paused, .doubleTap):
                return
            case (.idle, .doubleTap):
                return
            case (.completed, .doubleTap):
                return
        }
        
        print("new: \(self)")
    }
}

enum ProgressControlEvent {
    case tap
    case doubleTap
}

struct ProgressControl : View {
//    @State var isPlaying: Bool = false
    @State var state: ProgressControlState = .idle
    let size: CGFloat
    @State private var test: String = ""
    @State private var ratio: CGFloat = 0
    let onStart: () -> Void
    let onStop: () -> Void
    let id = UUID()
    @EnvironmentObject var store: MyAppStore
    
    var body: some View {
        ZStack {
            backgroundView
            controlImage
            ProgressArc(ratio: Double(ratio))
                .rotation(Angle(degrees: -90))
                .frame(width: size, height: size, alignment: .center)
        }
        .onTapGesture(count: 2) {
            state.handleEvent(event: .doubleTap, onStart: self.start, onStop: self.stop)
        }.onTapGesture(count: 1) {
            state.handleEvent(event: .tap, onStart: self.start, onStop: self.stop)
        }.onReceive(store.$state, perform: handleEvent(state:))
    }
    
    func handleEvent(state: MyAppState) {
        switch(state.tools.currentImage) {
            case .idle:
                self.state = .idle
            case .cancelled:
                self.state = .cancelled
            case .finished:
                self.state = .completed
            case .inProgress(let event):
                let ratio = event.completionRatio
                
                print("file: \(event.description) ratio: \(ratio)")
                self.ratio = ratio
                self.state = .active
            case .failed(_):
                self.state = .cancelled
        }
    }
    
    var backgroundView: some View {
        Circle()
            .foregroundColor(Color("DarkGray"))
            .frame(width: size, height: size, alignment: .center)
    }
    
    var controlImage: some View {
        func buildImage(name: String, isCustom: Bool = false) -> AnyView {
            if (isCustom) {
                return Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20, alignment: .center)
                    .eraseToAnyView()
            } else {
                return Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .center)
                    .eraseToAnyView()
            }
        }
        
        print("\(#function) id: \(self.id) \(self.state)")
        
        switch(self.state) {
            case .idle:
                return buildImage(name: "play.fill")
            case .active:
                return buildImage(name: "pause.fill")
            case .paused:
                return buildImage(name: "play.fill")
            case .completed:
                return buildImage(name: "play.fill")
            case .cancelled:
                return buildImage(name: "CancelIcon", isCustom: true)
        }
    }
    
    func start() {
        self.onStart()
    }
    
    func stop() {
        self.onStop()
    }
    
    struct ProgressArc: Shape {
        let ratio: Double
        
        private var startAngle: Angle {
            Angle(degrees: 0)
        }
        
        private var endAngle: Angle {
            let degrees = 360 * ratio + 1
            return Angle(degrees: degrees - 1.0)
        }
        
        func path(in rect: CGRect) -> Path {
            let lineWidth:CGFloat = 5
            let diameter = min(rect.size.width, rect.size.height)
            let radius = (diameter / 2.0) - (lineWidth / 2.0)
            let center = CGPoint(x: rect.origin.x + rect.size.width / 2.0,
                                 y: rect.origin.y + rect.size.height / 2.0)
            
            return Path { path in
                path.addArc(center: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false)
            }.strokedPath(.init(lineWidth: lineWidth))
        }
    }
}
