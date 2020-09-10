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
            
            Spacer()
            
            Button(action: {
                self.viewModel.displayAsList.toggle()
            }) {
                Text(self.viewModel.displayAsList ? "List" : "Grid")
//                Text(getListGridText())
            }
            
//            Spacer()
        }.padding(10)
    }
    
    func getListGridText() -> String {
        if (self.viewModel.displayAsList == true) {
            return "List"
        } else {
            return "Grid"
        }
    }
    /// Don't pass in the SquadViewModel directly to SquadCardView since we don't need
    /// the alertText, etc. from the view model for use in the SquadCardView
    var body: some View {
        VStack {
            header
            SquadCardView(squad: viewModel.squad, squadData: viewModel.squadData)
                .environmentObject(viewFactory)
                .environmentObject(self.pilotStateService)
                .onAppear() {
                    print("SquadView.onAppear")
                }
        }.alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.alertText),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct SquadCardViewModel {
    static func getShips(squad: Squad, squadData: SquadData) -> [ShipPilot] {
        let pilotStates = squadData.pilotStateArray.sorted(by: { $0.pilotIndex < $1.pilotIndex })
        _ = pilotStates.map{ print("pilotStates[\($0.pilotIndex)] id:\(String(describing: $0.id))") }
        
        let zipped: Zip2Sequence<[SquadPilot], [PilotState]> = zip(squad.pilots, pilotStates)
        
        _ = zipped.map{ print("\(String(describing: $0.0.name)): \($0.1)")}
        
        return zipped.map{
            getShip(squad: squad, squadPilot: $0.0, pilotState: $0.1)
        }
    }
}

struct UpgradeUtility {
    static func buildAllUpgrades(_ upgrades: SquadPilotUpgrade) -> [Upgrade] {
        func getJSONForUpgrade(forType: String, inDirectory: String) -> String {
            // Read json from file: forType.json
            let jsonFileName = "\(forType)"
            var upgradeJSON = ""
            
            if let path = Bundle.main.path(forResource: jsonFileName,
                                           ofType: "json",
                                           inDirectory: inDirectory)
            {
                print("path: \(path)")
                
                do {
                    upgradeJSON = try String(contentsOfFile: path)
                    print("upgradeJSON: \(upgradeJSON)")
                } catch {
                    print("error reading from \(path)")
                }
            }
            
            //            return modificationsUpgradesJSON
            return upgradeJSON
        }
        
        func getUpgrade(upgradeCategory: String, upgradeName: String) -> Upgrade {
            let jsonString = getJSONForUpgrade(forType: upgradeCategory, inDirectory: "upgrades")
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
            let matches: [Upgrade] = upgrades.filter({ $0.xws == upgradeName })
            
            let upgrade = matches[0]
            
            return upgrade
        }
        
        var allUpgrades : [Upgrade] = []
        
        let astromechs : [Upgrade] = upgrades
            .astromechs
            .map{ getUpgrade(upgradeCategory: "astromech", upgradeName: $0) }
        
        let cannons : [Upgrade] = upgrades
            .cannons
            .map{ getUpgrade(upgradeCategory: "cannon", upgradeName: $0) }
        
        let cargos : [Upgrade] = upgrades
            .cargos
            .map{ getUpgrade(upgradeCategory: "cargo", upgradeName: $0) }
        
        let commands : [Upgrade] = upgrades
            .commands
            .map{ getUpgrade(upgradeCategory: "command", upgradeName: $0) }
        
        let configurations : [Upgrade] = upgrades
            .configurations
            .map{ getUpgrade(upgradeCategory: "configuration", upgradeName: $0) }
        
        let crews : [Upgrade] = upgrades
            .crews
            .map{ getUpgrade(upgradeCategory: "crew", upgradeName: $0) }
        
        let devices : [Upgrade] = upgrades
            .devices
            .map{ getUpgrade(upgradeCategory: "device", upgradeName: $0) }
        
        let forcepowers : [Upgrade] = upgrades
            .forcepowers
            .map{ getUpgrade(upgradeCategory: "force-power", upgradeName: $0) }
        
        let gunners : [Upgrade] = upgrades
            .gunners
            .map{ getUpgrade(upgradeCategory: "gunner", upgradeName: $0) }
        
        let hardpoints : [Upgrade] = upgrades
            .hardpoints
            .map{ getUpgrade(upgradeCategory: "hardpoint", upgradeName: $0) }
        
        let illicits : [Upgrade] = upgrades
            .illicits
            .map{ getUpgrade(upgradeCategory: "illicit", upgradeName: $0) }
        
        let missiles : [Upgrade] = upgrades
            .missiles
            .map{ getUpgrade(upgradeCategory: "missile", upgradeName: $0) }
        
        let modifications : [Upgrade] = upgrades
            .modifications
            .map{ getUpgrade(upgradeCategory: "modification", upgradeName: $0) }
        
        let sensors : [Upgrade] = upgrades
            .sensors
            .map{ getUpgrade(upgradeCategory: "sensor", upgradeName: $0) }
        
        let tacticalrelays : [Upgrade] = upgrades
            .tacticalrelays
            .map{ getUpgrade(upgradeCategory: "tactical-relay", upgradeName: $0) }
        
        let talents : [Upgrade] = upgrades
            .talents
            .map{ getUpgrade(upgradeCategory: "talent", upgradeName: $0) }
        
        let teams : [Upgrade] = upgrades
            .teams
            .map{ getUpgrade(upgradeCategory: "team", upgradeName: $0) }
        
        let techs : [Upgrade] = upgrades
            .techs
            .map{ getUpgrade(upgradeCategory: "tech", upgradeName: $0) }
        
        let titles : [Upgrade] = upgrades
            .titles
            .map{ getUpgrade(upgradeCategory: "title", upgradeName: $0) }
        
        let torpedos : [Upgrade] = upgrades
            .torpedos
            .map{ getUpgrade(upgradeCategory: "torpedo", upgradeName: $0) }
        
        let turrets : [Upgrade] = upgrades
            .turrets
            .map{ getUpgrade(upgradeCategory: "turret", upgradeName: $0) }
        
        allUpgrades += astromechs
        allUpgrades += cannons
        allUpgrades += cargos
        allUpgrades += commands
        allUpgrades += configurations
        allUpgrades += crews
        allUpgrades += devices
        allUpgrades += forcepowers
        allUpgrades += gunners
        allUpgrades += hardpoints
        allUpgrades += illicits
        allUpgrades += missiles
        allUpgrades += modifications
        allUpgrades += sensors
        allUpgrades += tacticalrelays
        allUpgrades += talents
        allUpgrades += teams
        allUpgrades += techs
        allUpgrades += titles
        allUpgrades += torpedos
        allUpgrades += turrets

        return allUpgrades
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
    let foundPilots: Pilot = ship.pilots.filter{ $0.xws == squadPilot.id }[0]

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

struct SquadCardView: View {
    let squad: Squad
    let squadData: SquadData
    let theme: Theme = WestworldUITheme()
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var pilotStateService: PilotStateService
    @State var shipPilots: [ShipPilot] = []
    @State var activationOrder: Bool = true
    @State private var revealAllDials: Bool = false
    
    var emptySection: some View {
        Section {
            Text("No ships found")
        }
    }
    
    var sortedShipPilots: [ShipPilot] {
        var copy = self.shipPilots
        
        if (activationOrder) {
            copy.sort(by: { $0.ship.pilots[0].initiative < $1.ship.pilots[0].initiative })
        } else {
            copy.sort(by: { $0.ship.pilots[0].initiative > $1.ship.pilots[0].initiative })
        }
        
        return copy
    }
    
    var shipsSection: some View {
        Section {
            ForEach(sortedShipPilots) { shipPilot in
                Button(action: {
                    self.viewFactory.viewType = .shipViewNew(shipPilot, self.squad)
                }) {
                    self.buildPilotCardView(shipPilot: shipPilot, dialRevealed: self.revealAllDials)
//                        .environmentObject(self.pilotStateService)
                }
            }
        }
    }
    
    func buildPilotCardView(shipPilot: ShipPilot, dialRevealed: Bool) -> some View {
        print("PAK_Hide self.revealAllDials = \(self.revealAllDials)")
        
        return PilotCardView(shipPilot: shipPilot,
                      dialRevealed: dialRevealed)
    }
    
    func updateAllDials() {
        sortedShipPilots.forEach{ shipPilot in
            if var data = shipPilot.pilotStateData {
                data.change(update: {
                    print("PAK_\(#function) pilotStateData.id: \($0)")
                    $0.dial_revealed = self.revealAllDials
                    self.pilotStateService.updateState(newData: $0,
                                                       state: shipPilot.pilotState)
                    print("PAK_Hide updateAllDials $0.dial_revealed = \(self.revealAllDials)")
                })
            }
        }
    }
    
    var content: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(theme.BORDER_INACTIVE)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("\(squad.points ?? 0)")
                        .font(.title)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Button(action: {
                        self.activationOrder.toggle()
                    }) {
                        Text(self.activationOrder ? "Engage" : "Activate").foregroundColor(Color.white)
                        //                Text(getListGridText())
                    }
                    
                    Spacer()
                    
                    Text(squad.name ?? "Unnamed")
                        .font(.title)
                        .lineLimit(1)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                    
                    Spacer()
                    
                    Button(action: {
                        self.revealAllDials.toggle()
                        
                        print("PAK_Hide Button: \(self.revealAllDials)")
                        
                        self.updateAllDials()
                    }) {
                        Text(self.revealAllDials ? "Hide" : "Reveal").foregroundColor(Color.white)
                        //                Text(getListGridText())
                    }
                    
                    Spacer()
                    Text("\(damagedPoints)")
                        .font(.title)
                        .foregroundColor(theme.TEXT_FOREGROUND)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                }

                List {
                    if shipPilots.isEmpty {
                        emptySection
                    } else {
                        shipsSection
                    }
                }.clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                
                Spacer()
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .onAppear(perform: { self.shipPilots = SquadCardViewModel.getShips(squad: self.squad,
                                                                           squadData: self.squadData) })
        .frame(width: 600, height: 600)
    }
    
    var body: some View {
        content
    }
    
    var damagedPoints: Int {
        let points: [Int] = self.shipPilots.map { shipPilot in
            switch(shipPilot.healthStatus) {
            case .destroyed(let value):
                return value
            case .half(let value):
                return value
            default:
                return 0
            }
        }
        
        return points.reduce(0, +)
    }
}

// MARK:- Pilots
struct PilotCardView: View {
    let theme: Theme = WestworldUITheme()
    let shipPilot: ShipPilot
//    @EnvironmentObject var pilotStateService: PilotStateService
    @EnvironmentObject var viewFactory: ViewFactory
//    @State var dialRevealed: Bool
    let dialRevealed: Bool
    
    var newView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.BUTTONBACKGROUND)

            VStack {
                HStack {
                    Text("\(shipPilot.ship.pilots[0].initiative)")
                        .font(.title)
                        .bold()
                        .foregroundColor(Color.orange)
                    
                    Spacer()
                
                    VStack {
                        Text("\(shipPilot.pilot.name)")
                            .font(.body)
                    
                        Text("\(shipPilot.ship.name)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                    }

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
        print("PAK_Hide buildPilotDetailsView() self.dialRevealed = \(dialRevealed)")
        
        let viewModel = PilotDetailsViewModel(shipPilot: self.shipPilot,
                                              pilotStateService: self.viewFactory.diContainer.pilotStateService as PilotStateServiceProtocol,
                                              dialFlipped: self.dialRevealed)
        
        print("PAK_Hide buildPilotDetailsView().viewModel.dialFlipped = \(dialRevealed)")
        
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
    @Published var dialFlipped: Bool
    let shipPilot: ShipPilot
    let pilotStateService: PilotStateServiceProtocol
    
    init(shipPilot: ShipPilot,
         pilotStateService: PilotStateServiceProtocol,
         dialFlipped: Bool)
    {
        self.shipPilot = shipPilot
        self.pilotStateService = pilotStateService
        self.dialFlipped = dialFlipped
//        self.dialFlipped = self.shipPilot.pilotStateData?.dial_revealed ?? false
        print("PAK_Hide PilotDetailsViewModel.dialFlipped = \(self.dialFlipped)")
    }
    
    func flipDial() {
        self.dialFlipped.toggle()
        print("\(#function) self.dialFlipped=\(self.dialFlipped)")
        
        if var data = self.shipPilot.pilotStateData {
            data.change(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.dial_revealed = self.dialFlipped
                self.pilotStateService.updateState(newData: $0,
                                                   state: self.shipPilot.pilotState)
            })
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
                .frame(width: 65, height: 65, alignment: .center)
                .foregroundColor(Color.black)

            view
        })
    }
    
    var dialViewNew: some View {
        buildManeuverView(isFlipped: self.viewModel.dialFlipped)
            .padding(10)
            .rotation3DEffect(self.viewModel.dialFlipped ? Angle(degrees: 360): Angle(degrees: 0),
                          axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                // explicitly apply animation on toggle (choose either or)
                //withAnimation {
                self.viewModel.flipDial()
                //}
            }
    }
    
    var dialView: some View {
        IndicatorView(label:"99", bgColor: Color.black, fgColor: Color.blue)
            .rotation3DEffect(self.viewModel.dialFlipped ? Angle(degrees: 180): Angle(degrees: 0),
                          axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                // explicitly apply animation on toggle (choose either or)
                //withAnimation {
                self.viewModel.dialFlipped.toggle()
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
        }.padding(15)
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

func buildPilotDetailsViewModel(shipPilot: ShipPilot, pilotStateService: PilotStateService,
                                dialFlipped: Bool) -> PilotDetailsViewModel
{
    return PilotDetailsViewModel(shipPilot: shipPilot,
                                 pilotStateService: pilotStateService,
                                 dialFlipped: dialFlipped)
}

