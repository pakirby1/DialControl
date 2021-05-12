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
    var previousViewType: ViewType = .factionSquadList(.none)
    private var navigation = Navigation()
    var moc: NSManagedObjectContext
    var diContainer: DIContainer
    var store: MyAppStore
    
    init(moc: NSManagedObjectContext,
         diContainer: DIContainer,
         store: MyAppStore)
    {
        self.moc = moc
        self.diContainer = diContainer
        self.store = store
        self.navigation.push(type: .factionSquadList(.none))
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
    
    @Published var viewType: ViewType = .factionSquadList(.none) {
        willSet {
            navigation.push(type: newValue)
        }
    }
    
    func buildView() -> AnyView {
        if let type = navigation.current() {
            if FeaturesManager.shared.isFeatureEnabled(.MyRedux)
            {
                return Redux_buildView(type: type)
            } else {
                return buildView(type: type)
            }
        }
        
        return AnyView(Text("\(#function) : Invalid current view"))
    }
    
    func Redux_buildView(type: ViewType) -> AnyView {
        func buildShipView(shipPilot: ShipPilot, squad: Squad) -> AnyView {
            let viewModel = Redux_ShipViewModel(moc: self.moc,
                                          shipPilot: shipPilot,
                                          squad: squad,
                                          pilotStateService: self.diContainer.pilotStateService,
                                          store: store)
            
            return AnyView(Redux_ShipView(viewModel: viewModel)
                .environmentObject(self)
            )
        }
        
        switch(type) {
        case .toolsView:
            return AnyView(Redux_ToolsView()
                            .environmentObject(self)
                            .environmentObject(store))
                
        case .squadViewPAK(let squad, let squadData):
            return AnyView(Redux_SquadView(squad: squad,
                                     squadData: squadData)
                .environmentObject(self)
                .environmentObject(store)
            )
            
        case .shipViewNew(let shipPilot, let squad):
            return buildShipView(shipPilot: shipPilot, squad: squad)
            
        case .squadImportView:
            return AnyView(Redux_SquadXWSImportView()
                .environmentObject(self)
                .environmentObject(store)
                )
            
        case .multiLineTextView:
            return AnyView(MultilineTextView_ContentView())
        
        case .factionSquadList(let faction):
            return AnyView(Redux_FactionSquadList(faction: faction.rawValue)
                .environmentObject(self)
                .environmentObject(store))
            
        case .factionFilterView(let faction):
            return AnyView(Redux_FactionFilterView(faction: faction)
                .environmentObject(self)
                .environmentObject(store))
            
        case .back:
            self.navigation.back()
            if let current = self.navigation.current() {
                return Redux_buildView(type: current)
            } else {
                return AnyView(Text("Invalid back view on stack"))
            }
        }
    }
    
    func buildView(type: ViewType) -> AnyView {
        
        switch(type) {
        case .toolsView:
            return AnyView(Redux_ToolsView()
                            .environmentObject(self)
                            .environmentObject(store))
                
        case .squadViewPAK(let squad, let squadData):
            let viewModel = SquadViewModel(squad: squad,
                                           squadData: squadData)
            
            return AnyView(SquadView(viewModel: viewModel)
                .environmentObject(self)
                .environmentObject(self.diContainer.pilotStateService)
                .environmentObject(self.diContainer.squadService)
                )
            
        case .shipViewNew(let shipPilot, let squad):
            let viewModel = ShipViewModel(moc: self.moc,
                                          shipPilot: shipPilot,
                                          squad: squad,
                                          pilotStateService: self.diContainer.pilotStateService)
            
            return AnyView(ShipView(viewModel: viewModel)
                .environmentObject(self))
            
        case .squadImportView:
            return AnyView(SquadXWSImportView(viewModel: SquadXWSImportViewModel(moc: self.moc, squadService: self.diContainer.squadService, pilotStateService: self.diContainer.pilotStateService))
                .environmentObject(self)
                )
            
        case .multiLineTextView:
            return AnyView(MultilineTextView_ContentView())
        
        case .factionSquadList(let faction):
            return AnyView(FactionSquadList(viewModel: FactionSquadListViewModel(faction: faction.rawValue, moc: self.moc, squadService: self.diContainer.squadService))
                .environmentObject(self)
                .environmentObject(store))
            
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

enum Token: String, CaseIterable {
    case chargeActive = "Charge Active"
    case chargeInactive = "Charge Inactive"
    case shieldActive = "Shield Active"
    case shieldInactive = "Shield Inactive"
    case forceActive = "Force Active"
    case forceInactive = "Force Inactive"
    
    var characterCode: String {
        switch(self) {
        case .chargeActive: return "\u{00d3}"
        case .chargeInactive: return "\u{00d2}"
        case .forceActive: return "\u{00d5}"
        case .forceInactive: return "\u{00d4}"
        case .shieldActive: return "\u{00eb}"
        case .shieldInactive: return "\u{00d1}"
        }
    }
}

enum Faction: String, CaseIterable {
    case galacticrepublic = "Galactic Republic"
    case separatistalliance = "Separatist Alliance"
    case galacticempire = "Galactic Empire"
    case rebelalliance = "Rebel Alliance"
    case scumandvillainy = "Scum and Villainy"
    case resistance = "Resistance"
    case firstorder = "First Order"
    case none = ""
    
    var characterCode: String {
        switch(self) {
        case .galacticrepublic: return "\u{002f}" // Good
        case .separatistalliance: return "\u{002e}" // Good
        case .galacticempire: return "\u{0040}"
        case .rebelalliance: return "\u{002D}" // Good
        case .scumandvillainy: return "\u{0023}" // Good
        case .resistance: return "\u{0021}" // Good
        case .firstorder: return "\u{002B}"
        case .none: return ""
        }
    }
    
    var xwsID: String {
        switch(self) {
        case .galacticrepublic: return "galacticrepublic" // Good
        case .separatistalliance: return "separatistalliance" // Good
        case .galacticempire: return "galacticempire"
        case .rebelalliance: return "rebelalliance" // Good
        case .scumandvillainy: return "scumandvillainy" // Good
        case .resistance: return "resistance" // Good
        case .firstorder: return "firstorder"
        case .none: return ""
        }
    }
    
    static func buildFaction(jsonFaction: String) -> Faction? {
        if jsonFaction == "galacticempire" {
            return Faction.galacticempire
        }
        
        if jsonFaction == "galacticrepublic" {
            return Faction.galacticrepublic
        }
        
        if jsonFaction == "separatistalliance" {
            return Faction.separatistalliance
        }
        
        if jsonFaction == "rebelalliance" {
            return Faction.rebelalliance
        }
        
        if jsonFaction == "scumandvillainy" {
            return Faction.scumandvillainy
        }
        
        if jsonFaction == "resistance" {
            return Faction.resistance
        }
        
        if jsonFaction == "firstorder" {
            return Faction.firstorder
        }
        
        return nil
    }
}

enum ViewType {
    case shipViewNew(ShipPilot, Squad)
    case squadImportView
    case multiLineTextView
    case factionSquadList(Faction)
    case factionFilterView(Faction)
    case squadViewPAK(Squad, SquadData)
    case toolsView
    case back
}

extension ViewType: Equatable {
    static func ==(lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (let .shipViewNew(pilotA, _), let .shipViewNew(pilotB, _)):
            return pilotA == pilotB
            
        case (.squadImportView, .squadImportView):
            return true

        case (.multiLineTextView, .multiLineTextView):
            return true
        
        case (let .squadViewPAK(A), let .squadViewPAK(B)) :
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
