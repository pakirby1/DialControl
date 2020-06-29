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
import CoreData

class Navigation {
    var stack: [ViewType] = []
    
    func push(type: ViewType) {
        if !self.stack.contains(where: { $0 == type }) {
            self.stack.append(type)
            print("\(#function) Added \(type) to stack")
        }
    }
    
    func back() {
        _ = self.stack.popLast()
    }
    
    func current() -> ViewType? {
        return self.stack.last
    }
}

class ViewFactory: ObservableObject {
    var previousViewType: ViewType = .factionSquadList(.galactic_empire)
    private var navigation = Navigation()
    var moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        self.navigation.push(type: .factionSquadList(.galactic_empire))
    }
    
    func view(viewType: ViewType) {
        self.navigation.stack.removeAll()
        self.viewType = viewType
    }
    
    func back() {
        self.navigation.back()
        
        if let current = self.navigation.current() {
            self.viewType = current
        }
    }
    
    @Published var viewType: ViewType = .factionSquadList(.galactic_empire) {
        willSet {
            navigation.push(type: newValue)
        }
    }
    
    func buildView() -> AnyView {
        if let type = navigation.current() {
            return buildView(type: type)
        }
        
        return AnyView(Text("\(#function) : Invalid current view"))
    }
    
    private func buildView(type: ViewType) -> AnyView {
        
        switch(type) {
        case .squadViewPAK(let json):
            return AnyView(SquadView(jsonString: json)
                .environmentObject(self))
            
        case .squadView:
            return AnyView(SquadView(jsonString: squadJSON)
                .environmentObject(self))
            
        case .shipViewNew(let shipPilot):
            return AnyView(ShipView(viewModel: ShipViewModel(moc: self.moc, shipPilot: shipPilot))
                .environmentObject(self))
            
        case .squadImportView:
            return AnyView(SquadXWSImportView(viewModel: SquadXWSImportViewModel(moc: self.moc))
                .environmentObject(self)
                )
            
        case .multiLineTextView:
            return AnyView(MultilineTextView_ContentView())
        
        case .squadViewNew(let jsonString):
            return AnyView(SquadView(jsonString: jsonString)
                .environmentObject(self))
            
        case .factionSquadList(let faction):
            return AnyView(FactionSquadList(viewModel: FactionSquadListViewModel(faction: faction.rawValue, moc: self.moc))
                .environmentObject(self))
            
        case .factionFilterView(let faction):
            return AnyView(FactionFilterView(faction: faction)
                .environmentObject(self))
            
        case .back:
            self.navigation.back()
            if let current = self.navigation.current() {
                return buildView(type: current)
            } else {
                return AnyView(Text("Invalid back view on stack"))
            }
        }
    }
}

enum Faction: String, CaseIterable {
    case galactic_republic = "Galactic Republic"
    case separatists = "Separatists"
    case galactic_empire = "Galactic Empire"
    case rebel_alliance = "Rebel Alliance"
    case scum_villiany = "Scum & Villiany"
    case resistance = "Resistance"
    case first_order = "First Order"
}

enum ViewType {
    case squadView
//    case shipView(SquadPilot)
    case shipViewNew(ShipPilot)
    case squadImportView
    case multiLineTextView
    case squadViewNew(String)
    case factionSquadList(Faction)
    case factionFilterView(Faction)
    case squadViewPAK(String)
    case back
}

extension ViewType: Equatable {
    static func ==(lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.squadView, .squadView):
            return true
            
        case (let .shipViewNew(pilotA), let .shipViewNew(pilotB)):
            return pilotA == pilotB

        case (.squadImportView, .squadImportView):
            return true

        case (.multiLineTextView, .multiLineTextView):
            return true
            
        case (let .squadViewNew(A), let .squadViewNew(B)):
            return A == B

        case (.factionSquadList, .factionSquadList):
            return true

        case (.factionFilterView, .factionFilterView):
            return true
            
        default:
            return false
        }
    }
}


struct ContentView: View {
    @State var maneuver: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    let theme: Theme = WestworldUITheme()
    
    var body: some View {
        VStack {
//            viewFactory.buildView(type: viewFactory.viewType)
            viewFactory.buildView()
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
