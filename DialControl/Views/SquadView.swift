//
//  SquadView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/22/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

// MARK:- SquadView
class SquadViewModel : ObservableObject {
    @Published var alertText: String = ""
    @Published var showAlert: Bool = false
    var squad: Squad
    var squadData: SquadData
    @Published var displayAsList: Bool = true

    init(squad: Squad,
         squadData: SquadData)
    {
        self.squad = squad
        self.squadData = squadData
    }
}

struct SquadViewState {
    
  let activateInitiativeOrder: Bool = true
  let hideAllDials: Bool = true
}

struct SquadView: View {
    @State var maneuver: String = ""
    @EnvironmentObject var viewFactory: ViewFactory
    @ObservedObject var viewModel: SquadViewModel
    @EnvironmentObject var pilotStateService: PilotStateService
    @EnvironmentObject var squadService: SquadService
    @State var isFirstPlayer: Bool = false
    @State private var displayResetAllConfirmation: Bool = false
    
    init(viewModel: SquadViewModel) {
        self.viewModel = viewModel
    }
    
    
    
    var header: some View {
        HStack {
            Button(action: {
                self.viewFactory.back()
            }) {
                Text("< Faction Squad List")
            }
           
            Toggle(isOn: self.$isFirstPlayer.didSet{
                // Hack because swift thinks I don't want to perform
                // an assignment (=) vs. a boolean check (==)
                let x = $0
                self.viewModel.squadData.firstPlayer = x
                self.squadService.updateSquad(squadData: self.viewModel.squadData)
            }){
                Text("First Player")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
        }.padding(10)
    }
    
    /// Don't pass in the SquadViewModel directly to SquadCardView since we don't need
    /// the alertText, etc. from the view model for use in the SquadCardView
    var body: some View {
        return VStack {
            header
            SquadCardView(squad: viewModel.squad,
                          squadData: viewModel.squadData,
                          displayAsList: self.viewModel.displayAsList, isFirstPlayer: $isFirstPlayer)
                .environmentObject(viewFactory)
                .environmentObject(self.pilotStateService)
                .environmentObject(self.squadService)
                .onAppear() {
                    print("SquadView.onAppear")
                }
            
            
        }
        .onAppear() {
            self.isFirstPlayer = self.viewModel.squadData.firstPlayer
        }
    }
}

struct SquadCardViewModel {
    static func getShips(squad: Squad, squadData: SquadData) -> [ShipPilot] {
        let pilotStates = squadData.pilotStateArray.sorted(by: { $0.pilotIndex < $1.pilotIndex })
        _ = pilotStates.map{ print("pilotStates[\($0.pilotIndex)] id:\(String(describing: $0.id))") }
        
        let zipped: Zip2Sequence<[SquadPilot], [PilotState]> = zip(squad.pilots, pilotStates)
        
        _ = zipped.map{ print("\(String(describing: $0.0.name)): \($0.1)")}
        
        let ret = zipped.map{
            getShip(squad: squad, squadPilot: $0.0, pilotState: $0.1)
        }
        
        ret.printAll(tag: "PAK_DialStatus getShips()")
        
        return ret
    }
}

func getShip(squad: Squad, squadPilot: SquadPilot, pilotState: PilotState) -> ShipPilot {
    var shipJSON: String = ""
    
    print("shipName: \(squadPilot.ship)")
    print("pilotName: \(squadPilot.name)")
    print("faction: \(squad.faction)")
    print("pilotStateId: \(String(describing: pilotState.id))")
    
    shipJSON = getJSONFor(ship: squadPilot.ship, faction: squad.faction)
    
    var ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
    let foundPilots: PilotDTO = ship.pilots.filter{ $0.xws == squadPilot.id }[0]

    ship.pilots.removeAll()
    ship.pilots.append(foundPilots)
    
    var allUpgrades : [Upgrade] = []
    
    // Add the upgrades from SquadPilot.upgrades by iterating over the
    // UpgradeCardEnum cases and calling getUpgrade
    if let upgrades = squadPilot.upgrades {
        allUpgrades = UpgradeUtility.buildAllUpgrades(upgrades)
    }
   
    return ShipPilot(ship: ship,
                     upgrades: allUpgrades,
                     points: squadPilot.points,
                     pilotState: pilotState)
}

struct SquadCardView: View, DamagedSquadRepresenting {
    let squad: Squad
    let squadData: SquadData
    let displayAsList: Bool
    let theme: Theme = WestworldUITheme()
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var pilotStateService: PilotStateService
    @EnvironmentObject var squadService: SquadService
    @State var shipPilots: [ShipPilot] = []
    @State var activationOrder: Bool = true
    @State private var revealAllDials: Bool = false
    @Binding var isFirstPlayer: Bool
    @State private var displayResetAllConfirmation: Bool = false
    
    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    private var shipsView: AnyView {
        switch displayAsList {
        case true: return AnyView(shipsGrid)
        case false: return AnyView(shipsGrid)
        }
    }
    
    var chunkedShips : [[ShipPilot]] {
        return sortedShipPilots.chunked(into: 2)
    }
    
    var sortedShipPilots: [ShipPilot] {
        // TODO: Switch & AppStore
        var copy = self.shipPilots
        
        if (activationOrder) {
            copy.sort(by: { $0.ship.pilots[0].initiative < $1.ship.pilots[0].initiative })
        } else {
            copy.sort(by: { $0.ship.pilots[0].initiative > $1.ship.pilots[0].initiative })
        }
        
        return copy
    }
    
    var shipsListSection: some View {
        Section {
            ForEach(sortedShipPilots) { shipPilot in
                self.buildShipButton(shipPilot: shipPilot)
            }
        }
    }
    
    var shipsGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ForEach(0..<chunkedShips.count) { index in
                HStack {
                    ForEach(self.chunkedShips[index]) { shipPilot in
                        self.buildShipButton(shipPilot: shipPilot)
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    func buildPilotCardView(shipPilot: ShipPilot) -> AnyView {
                // Get the dial status from the pilot state
                if let data = shipPilot.pilotStateData {
                    print("PAK_Hide shipPilot.pilotStateData.dial_status = \(data.dial_status)")
                    return AnyView(PilotCardView(shipPilot: shipPilot,
                                        dialStatus: data.dial_status))
                }

                return AnyView(EmptyView())
                // FIXME: Why do we need this?
    //            return PilotCardView(shipPilot: shipPilot,
    //                                 dialStatus: dialRevealed ? .hidden : .revealed)
            }
    
    func buildShipButton(shipPilot: ShipPilot) -> some View {
        
        
        return Button(action: {
            self.viewFactory.viewType = .shipViewNew(shipPilot, self.squad)
        }) {
            buildPilotCardView(shipPilot: shipPilot)
        }
    }
    
    func updateAllDials() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                if data.dial_status != .destroyed {
                    data.change(update: {
                        print("PAK_DialStatus pilotStateData.id: \($0)")
                        let revealAllDialsStatus: DialStatus = self.revealAllDials ? .revealed : .hidden
                        $0.dial_status = revealAllDialsStatus
                        self.pilotStateService.updateState(newData: $0,
                                                           state: shipPilot.pilotState)
                        print("PAK_DialStatus updateAllDials $0.dial_status = \(revealAllDialsStatus)")
                        print("PAK_DialStatus updateAllDials $0.dial_revealed = \(self.revealAllDials)")
                    })
                }
            }
        }
        
        // reload ships
        // TODO: Switch & AppStore
        loadShips()
    }
    
    func resetAllShips() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                data.change(update: {
                    $0.reset()
                    
                    self.pilotStateService.updateState(
                        newData: $0,
                        state: shipPilot.pilotState)
                })
            }
        }
        
        // Not sure why, but this forces a refresh of the ship status (Half, Destroyed)
        // It updatee the @State shipPilots
        
        // TODO: Switch & AppStore
        self.shipPilots = []
        // reload ships
        // TODO: Switch & AppStore
        loadShips()
    }
    
    var body: some View {
        let points = Text("\(squad.points ?? 0)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
        
        let engage = Button(action: {
            self.activationOrder.toggle()
            self.squadData.engaged = self.activationOrder
            self.squadService.updateSquad(squadData: self.squadData)
        }) {
            Text(self.activationOrder ? "Engage" : "Activate").foregroundColor(Color.white)
        }
        
        let title = Text(squad.name ?? "Unnamed")
            .font(.title)
            .lineLimit(1)
            .foregroundColor(theme.TEXT_FOREGROUND)
        
        let hide = Button(action: {
            self.revealAllDials.toggle()
            
            print("PAK_DialStatus_New Button: \(self.revealAllDials)")
        
            self.updateAllDials()
        }) {
            Text(self.revealAllDials ? "Hide" : "Reveal").foregroundColor(Color.white)
        }
        
        let reset = Button(action: {
            self.displayResetAllConfirmation = true
        }) {
            Text("Reset All")
                .font(.title)
                .foregroundColor(Color.red)
        }.alert(isPresented: $displayResetAllConfirmation) {
            Alert(
                title: Text("Reset All"),
                message: Text("Reset All Ships"),
                primaryButton: Alert.Button.default(Text("Reset"), action: { self.resetAllShips() }),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
            )
        }
        
        let damaged = Text("\(damagedPoints)")
            .font(.title)
            .foregroundColor(theme.TEXT_FOREGROUND)
            .padding()
            .background(Color.red)
            .clipShape(Circle())
        
        var firstPlayer: some View {
            if isFirstPlayer == true {
                return AnyView(firstPlayerSymbol)
            }
            
            return AnyView(EmptyView())
        }
        
        return ZStack {
            VStack(alignment: .leading) {
                // Header
                HStack {
                    points

                    Spacer()

                    engage

                    Spacer()

                    title

                    firstPlayer

                    Spacer()

                    hide

                    Spacer()

                    damaged
                }.padding(20)

                // Body
                // TODO: Switch & AppStore
                if shipPilots.isEmpty {
                    emptySection
                } else {
                    shipsView
                }
                
                // Footer
                CustomDivider()
                HStack {
                    Spacer()
                    reset
                    Spacer()
                }
            }
            .multilineTextAlignment(.center)
        }
        .onAppear{
            print("PAK_DialStatus SquadCardView.onAppear()")
            // TODO: Switch & AppStore
            self.loadShips()
            self.activationOrder = self.squadData.engaged
        }
    }
    
    // TODO: Switch & AppStore
    func loadShips() {
        logMessage("damagedPoints SquadCardView.loadShips")
        print("PAK_DialStatus SquadCardView.loadShips()")
        self.shipPilots = SquadCardViewModel.getShips(
            squad: self.squad,
            squadData: self.squadData)

        self.shipPilots.printAll(tag: "PAK_DialStatus self.shipPilots")

        self.shipPilots.forEach{ shipPilot in
            print("PAK_DialStatus SquadCardView.loadShips() \(shipPilot.id) \(shipPilot.pilotState.json ?? "No JSON")")
        }
    }
}

// MARK:- Pilots
struct PilotCardView: View {
    let theme: Theme = WestworldUITheme()
    let shipPilot: ShipPilot
//    @EnvironmentObject var pilotStateService: PilotStateService
    @EnvironmentObject var viewFactory: ViewFactory
//    @State var dialRevealed: Bool
    @State var dialStatus: DialStatus
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                HStack {
//                    Text("\(shipPilot.ship.pilots[0].initiative)")
//                        .font(.title)
//                        .bold()
//                        .foregroundColor(Color.orange)
                    
                    initiative
                    
                    Spacer()
                
//                    VStack {
//                        Text("\(shipPilot.pilot.name)")
//                            .font(.body)
//
//                        Text("\(shipPilot.ship.name)")
//                            .font(.caption)
//                            .foregroundColor(Color.white)
//                    }
                    
                    pilotShipNames

                    Spacer()
                    
                    halfStatus
                }
                .padding(.leading, 5)
                .background(Color.black)
                
                Spacer()
                
                // https://medium.com/swlh/swiftui-and-the-missing-environment-object-1a4bf8913ba7
                
                buildPilotDetailsView()
                
//                PilotDetailsView(viewModel: PilotDetailsViewModel(shipPilot: self.shipPilot, pilotStateService: self.pilotStateService),
//                                 displayUpgrades: true,
//                                 displayHeaders: false,
//                                 displayDial: true)
                
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .multilineTextAlignment(.center)
        }
    }
    
    func buildPilotDetailsView() -> some View {
        print("PAK_DialStatus buildPilotDetailsView() self.dialStatus = \(dialStatus)")
        
        let viewModel = PilotDetailsViewModel(shipPilot: self.shipPilot,
                                              pilotStateService: self.viewFactory.diContainer.pilotStateService as PilotStateServiceProtocol)
        
        print("PAK_DialStatus buildPilotDetailsView().viewModel.dialStatus = \(dialStatus)")
        
        return PilotDetailsView(viewModel: viewModel,
            displayUpgrades: true,
            displayHeaders: false,
            displayDial: true)
    }
    
    var body: some View {
        newView
            .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.BORDER_ACTIVE, lineWidth: 2)
        )
    }
    
    var halfStatus: some View {
        if let data = shipPilot.pilotStateData {
            if data.isDestroyed {
                return Text("Destroyed").padding(5).foregroundColor(Color.red)
            } else if data.isHalved {
                return Text("Half").padding(5).foregroundColor(Color.yellow)
            }
        }
        
        return Text("").padding(5).foregroundColor(Color.white)
    }
    
    var initiative: some View {
        Text("\(shipPilot.ship.pilots[0].initiative)")
            .font(.title)
            .bold()
            .foregroundColor(Color.orange)
    }
    
    var pilotShipNames: some View {
        VStack {
            Text("\(shipPilot.pilot.name)")
                .font(.body)
                .foregroundColor(Color.white)
            
            Text("\(shipPilot.ship.name)")
                .font(.caption)
                .foregroundColor(Color.white)
        }
    }
}

struct IndicatorView: View {
    let label: String
    let bgColor: Color
    let fgColor: Color
    
    var body: some View {
        Text("\(label)")
            .font(.title)
            .foregroundColor(fgColor)
            .padding()
            .background(bgColor)
            .clipShape(Circle())
    }
}

class PilotDetailsViewModel: ObservableObject {
    @Published var shipPilot: ShipPilot
    let pilotStateService: PilotStateServiceProtocol
    
    init(shipPilot: ShipPilot,
         pilotStateService: PilotStateServiceProtocol)
    {
        self.shipPilot = shipPilot
        self.pilotStateService = pilotStateService
    }
    
    func flipDial() {
        if var data = self.shipPilot.pilotStateData {
            guard !data.isDestroyed else {
                // Do not flip if destroyed
                return
            }
            
            data.change(update: {
                var newPSD = $0
                
                print("\(Date()) PAK_\(#function) before pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                newPSD.dial_status.handleEvent(event: .dialTapped)
                
                // Update CoreData
                self.pilotStateService.updateState(newData: newPSD,
                                                   state: self.shipPilot.pilotState)
                print("\(Date()) PAK_\(#function) after pilotStateData id: \(self.shipPilot.id) dial_status: \(newPSD.dial_status)")
                
                // self.shipPilot.pilotState.json was updated but
                // the self.shipPilot property was NOT updated so no refesh taken
                // Hack to force refresh of view
                self.objectWillChange.send()
            })
        }
        
        if let _ = self.shipPilot.pilotStateData {
            print("\(Date()) PAK_\(#function) pilotStateData id: \(self.shipPilot.id) dial_status: \(self.shipPilot.pilotStateData?.dial_status)")
        }
    }
}

struct PilotDetailsView: View {
    @ObservedObject var viewModel: PilotDetailsViewModel
    let displayUpgrades: Bool
    let displayHeaders: Bool
    let displayDial: Bool
    let theme: Theme = WestworldUITheme()
    @State var currentManeuver: String = ""
    
    func buildPointsView(half: Bool = false) -> AnyView {
        let points = half ? self.viewModel.shipPilot.halfPoints : self.viewModel.shipPilot.points
        let color = half ? Color.red : Color.blue
        let label = "\(points)"
        
        return AnyView(IndicatorView(label:label,
                                     bgColor: color,
                                     fgColor: theme.TEXT_FOREGROUND))
    }
    
    /*
     maneuverList
     ▿ 7 : 3L
       - speed : 3
       - bearing : DialControl.ManeuverBearing.L
       - difficulty : DialControl.ManeuverDifficulty.R
     ▿ 8 : 3T
       - speed : 3
       - bearing : DialControl.ManeuverBearing.T
       - difficulty : DialControl.ManeuverDifficulty.W
     */
    
    func buildManeuverView(isFlipped: Bool) -> AnyView {
        let x = self.viewModel.shipPilot.selectedManeuver
        var view: AnyView = AnyView(EmptyView())
        
        if isFlipped {
            if x.count > 0 {
                let m = Maneuver.buildManeuver(maneuver: x)
                view = m.view
            }
        } else {
            view = AnyView(Text("Dial").padding(15))
        }
    
        return AnyView(ZStack {
            Circle()
                .frame(width: 75, height: 75, alignment: .center)
                .foregroundColor(Color.black)

            view
        })
    }
    
    func buildManeuverView(dialStatus: DialStatus) -> AnyView {
        print("\(Date()) PAK_DialStatus buildManeuverView() \(self.viewModel.shipPilot.id) \(dialStatus)")
        let ionManeuver = "1FB"
        
        var foregroundColor: Color {
            let ret: Color
            
            switch(dialStatus) {
                case .destroyed:
                    ret = Color.red
                default:
                    ret = Color.black
            }
            
            return ret
        }
        
        var strokeColor: Color {
            let ret: Color
            
            switch(dialStatus) {
                case .set:
                    ret = Color.white
                case .ionized:
                    ret = Color.red
                default:
                    ret = Color.clear
            }
            
            return ret
        }
        
        let x = self.viewModel.shipPilot.selectedManeuver
        var view: AnyView = AnyView(EmptyView())
        
        switch(dialStatus) {
            case .hidden, .destroyed:
                view = AnyView(Text("").padding(15))
            case .ionized:
                view = Maneuver.buildManeuver(maneuver: ionManeuver).view
            case .revealed, .set:
                if x.count > 0 {
                    let m = Maneuver.buildManeuver(maneuver: x)
                    view = m.view
                }
        }
    
        return AnyView(ZStack {
            Circle()
                .frame(width: 75, height: 75, alignment: .center)
                .foregroundColor(foregroundColor)

            Circle()
                .stroke(strokeColor, lineWidth: 3)
                .frame(width: 75, height: 75, alignment: .center)

            view
        })
    }
    
    var dialViewNew: some View {
        let status = self.viewModel.shipPilot.pilotStateData!.dial_status
        
        print("\(Date()) PAK_DialStatus dialViewNew \(self.viewModel.shipPilot.id) \(self.viewModel.shipPilot.pilotName) \(status)")
        
        return buildManeuverView(dialStatus: status)
            .padding(10)
//            .rotation3DEffect(isFlipped ? Angle(degrees: 360): Angle(degrees: 0),
//                          axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                // explicitly apply animation on toggle (choose either or)
                //withAnimation {
                self.viewModel.flipDial()
                //}
            }
    }
    
    var names: some View {
        VStack {
            Text("\(self.viewModel.shipPilot.ship.pilots[0].name)")
                .font(.title)
                .foregroundColor(theme.TEXT_FOREGROUND)
            
            Text("\(self.viewModel.shipPilot.ship.name)")
                .font(.body)
                .foregroundColor(theme.TEXT_FOREGROUND)
        }
    }
    
    var upgrades: some View {
        VStack(alignment: .leading) {
            if (displayUpgrades) {
                ForEach(self.viewModel.shipPilot.upgrades) { upgrade in
                    Text("\(upgrade.name)")
                        .foregroundColor(Color.white)
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            buildPointsView()
            
            buildPointsView(half: true)
            
            IndicatorView(label: "\(self.viewModel.shipPilot.threshold)",
                bgColor: Color.yellow,
                fgColor: Color.black)
            
            // Pilot Details
//            names
            
            Spacer()
            
            // Upgrades
            upgrades
            
            Spacer()
            
//            dialView
            if (displayDial) {
                dialViewNew
            }
        }
        .padding(15)
        .onReceive(viewModel.$shipPilot, perform: { shipPilot in
            print("\(Date()) PilotDetailsView.body.onReceive \(shipPilot)")
        })
        .onAppear() {
            print("\(Date()) PilotDetailsView.body.onAppear")
        }
    }
}

struct SimpleFlipper : View {
      @State var flipped = false

      var body: some View {

        let flipDegrees: Double = flipped ? 180.0 : 0

            return VStack{
                  Spacer()

                  ZStack() {
                    Text("Front")
//                        .placedOnCard(Color.yellow)
//                        .flipRotate(flipDegrees)
                        .opacity(flipped ? 0.0 : 1.0)
                        .clipShape(Circle())
                    
                    Text("Back")
//                        .placedOnCard(Color.blue)
//                        .flipRotate(-180 + flipDegrees)
                        .opacity(flipped ? 1.0 : 0.0)
                        .clipShape(Circle())
                  }
                  .animation(.easeInOut(duration: 0.8))
                  .onTapGesture { self.flipped.toggle() }
                  Spacer()
            }
      }
}

//struct ShipGridView : View {
//    let chunkedDishes = ShipGridView.getChunkedArray()
//
//    var body: some View {
//        List {
//            ForEach(0..<chunkedDishes.count) { index in
//                HStack {
//                    ForEach(self.chunkedDishes[index]) { cell in
//                        CardView(cell: cell)
//                    }
//                }
//            }
//        }
//    }
//
//    static func getChunkedArray() -> [[Cell]] {
//        let chunkedDishes = Row.all_flat().chunked(into: 2)
//        return chunkedDishes
//    }
//}

extension Array where Element == ShipPilot {
    func printAll(tag: String) {
        self.forEach{ shipPilot in
            print("\(tag) \(shipPilot.id) \(shipPilot.pilotState.json ?? "No JSON")")
        }
    }
}
