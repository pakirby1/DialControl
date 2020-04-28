//
//  ContentView.swift
//  DialControl
//
//  Created by Phil Kirby on 2/15/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import SwiftUI
import Combine
import TimelaneCombine

class ViewFactory: ObservableObject {
    @Published var viewType: ViewType = .factionSquadList(.galactic_empire)
    let textViewObservable = TextViewObservable()
    
    func buildView(type: ViewType) -> AnyView {
        switch(type) {
        case .squadView:
            return AnyView(SquadView(jsonString: squadJSON).environmentObject(self))
        case .shipViewNew(let shipPilot):
            return AnyView(ShipView(viewModel: ShipViewModel(shipPilot: shipPilot))
                .environmentObject(self))
        case .squadImportView:
            return AnyView(SquadXWSImportView()
                .environmentObject(self)
                .environmentObject(textViewObservable)
                )
        case .multiLineTextView:
            return AnyView(MultilineTextView_ContentView())
        case .squadViewNew(let jsonString):
            return AnyView(SquadView(jsonString: jsonString).environmentObject(self))
        case .factionSquadList(let faction):
            return AnyView(FactionSquadList(faction: faction.rawValue).environmentObject(self))
        }
    }
}

enum Faction: String {
    case galactic_empire = "Galactic Empire"
}

enum ViewType {
    case squadView
//    case shipView(SquadPilot)
    case shipViewNew(ShipPilot)
    case squadImportView
    case multiLineTextView
    case squadViewNew(String)
    case factionSquadList(Faction)
}

struct ContentView: View {
    @State var maneuver: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    let theme: Theme = WestworldUITheme()
    
    var body: some View {
        VStack {
            viewFactory.buildView(type: viewFactory.viewType)
        }.onAppear() {
            print("ContentView.onAppear")
        }
//        .border(Color.green, width: 2)
//            .background(theme.BORDER_INACTIVE)
    }
}

// Hold down the option key and drag to rotate
struct Rotation: View {
    enum RotationState {
        case inactive
        case rotating(angle: Angle)
        
        var rotationAngle: Angle {
            switch self {
            case .rotating(let angle):
                return angle
            default:
                return Angle.zero
            }
        }
    }
    
    var anglePublisher = PassthroughSubject<Angle, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    @GestureState var rotationState = RotationState.inactive
    @State var viewRotationState = Angle(degrees: 0.0)
    
    var totalRotation: CGFloat = CGFloat()
    var totalSegments: UInt = 4
    @State var currentSegment: UInt = 0
    
    init() {
        anglePublisher
            .lane("anglePublisher")
            .sink{ value in
                print("rotated: \(value.degrees) from top")
            }
            .store(in: &cancellables)
    }
    
    var rotationAngle: Angle {
        print("viewRotationState: \(viewRotationState.degrees) rotationAngle: \(rotationState.rotationAngle.degrees)")
        var ret = viewRotationState + rotationState.rotationAngle
        
        if ret.degrees < 0 {
            ret = Angle(degrees: 360.0) + ret
        }
        
        anglePublisher.send(ret)
        
//        // figure out the segment
//        let segmentAngle = 360.0 / Double(totalSegments)
//        currentSegment = UInt(ret.degrees / segmentAngle)
        
        return ret
    }
    
    var rotationHistory: [Angle] = []
    
    var body: some View {
        
        let rotationGesture = RotationGesture(minimumAngleDelta: Angle(degrees: 1))
            .updating($rotationState) { value, state, transation in
                state = .rotating(angle: value)
        }.onEnded { value in
            self.viewRotationState += value
            let segmentAngle = 360.0 / Double(self.totalSegments)
            let tempSegment = self.rotationAngle.degrees / segmentAngle
//            self.currentSegment = UInt()
            print("onEnded.value: \(value.degrees) viewRotationState: \(self.viewRotationState.degrees) segmentAngle: \(segmentAngle) tempSegment: \(tempSegment)")
        }
        
        return
            ZStack {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 350, height: 650)
                    .rotationEffect(rotationAngle)
                    .gesture(rotationGesture)
                
                VStack {
                    Text("Angle: \(rotationAngle.degrees)").font(.title)
                    Text("Segment: \(currentSegment)").font(.title)
//                    Text("\(rotationState.rotationAngle.degrees)").font(.title)
                }
            }
    }
}
