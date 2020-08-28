//
//  ShipView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/25/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine
import CoreData

// MARK:- ShipViewModel
class ShipViewModel: ObservableObject {
    var shipPilot: ShipPilot
    var squad: Squad
    @Published var shipImage: UIImage = UIImage()
    @Published var upgradeImage: UIImage = UIImage()
    private var _displayImageOverlay: Bool = false
    private var cancellableSet = Set<AnyCancellable>()
    var pilotStateData: PilotStateData
    let pilotStateService: PilotStateServiceProtocol
    var pilotState: PilotState? = nil
    @Published var currentManeuver: String = ""

    // CoreData
    private let frc: BindableFetchedResultsController<ImageData>
    let moc: NSManagedObjectContext
    
    // Images Support
//    @ObservedObject var networkCacheViewModel: NetworkCacheViewModel
    @Published var images: [ImageData] = []
    
    init(moc: NSManagedObjectContext,
         shipPilot: ShipPilot,
         squad: Squad,
         pilotStateService: PilotStateServiceProtocol)
    {
        self.shipPilot = shipPilot
        self.squad = squad
        self.pilotStateService = pilotStateService
        self.pilotStateData = shipPilot.pilotStateData!
        self.pilotState = shipPilot.pilotState
        
        // CoreData
        self.moc = moc
        self.frc = BindableFetchedResultsController<ImageData>(fetchRequest: ImageData.fetchAll(),
            managedObjectContext: moc)

        // set the maneuver
        if let data = self.shipPilot.pilotStateData {
            self.currentManeuver = data.selected_maneuver
        }
        
        // take the stream generated by the frc and @Published fetchedObjects
        // and assign it to
        // players.  This way clients don't have to access viewModel.frc.fetchedObjects
        // directly.  Use $ to geet access to the publisher of the @Published.
        let q = DispatchQueue(label: "ShipViewModel")
        
        self.frc
            .$fetchedObjects
            .print()
            .receive(on: DispatchQueue.main)
            .assign(to: \ShipViewModel.images, on: self)
            .store(in: &cancellableSet)
        
        self.$currentManeuver
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .print("Hello")
            .receive(on: DispatchQueue.main)
            .lane("currentManeuver")
            .sink(receiveValue: {
                self.updateSelectedManeuver(maneuver: $0)
            })
            .store(in: &cancellableSet)
    }
    
    var displayImageOverlay: Bool {
        get {
            return _displayImageOverlay
        }
        set {
            _displayImageOverlay = newValue
        }
    }
    
    lazy var shipImageURL: String = {
        loadShipFromJSON(shipName: shipPilot.shipName,
                       pilotName: shipPilot.pilotName).1.image
    }()
    
    /// What do we return if we encounter an error (empty file)?
    func loadShipFromJSON(shipName: String, pilotName: String) -> (Ship, Pilot) {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        shipJSON = getJSONFor(ship: shipName, faction: squad.faction)
        
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        let foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0]
        
        return (ship, foundPilots)
    }
    
    func loadPilotStateFromCoreData() {
        do {
            let fetchRequest = PilotState.fetchRequest()
            let pilotStates = try self.moc.fetch(fetchRequest) as! [PilotState]
            
            if pilotStates.count > 0 {
                _ = pilotStates.map{ print("\(String(describing: $0.id)) shipPilot.pilotStateId \(shipPilot.pilotState.id)") }
                
                let filtered = pilotStates.filter{ $0.id == shipPilot.pilotState.id }
                
                if filtered.count == 1 {
                    guard let state: PilotState = filtered.first else { return }
                    guard let json = state.json else { return }
                    let data: PilotStateData = PilotStateData.deserialize(jsonString: json)
                    self.pilotStateData = data
                    self.pilotState = state
                }
            }
        } catch {
            print(error)
        }
    }
    
    // Load values from pilotShipState, becuase shipPilot ontains the initial values
    // Not the updated values
    var force: Int {
        return shipPilot.ship.pilots[0]
            .force?.value ?? 0
    }
    
    var charges: Int {
        return shipPilot.ship.pilots[0]
            .charges?.value ?? 0
    }
    
    var shieldsActive: Int {
//        self.shipPilot.shieldStats
        return self.pilotStateData.shield_active
    }
    
    var hullActive: Int {
//        self.shipPilot.hullStats
        return self.pilotStateData.hull_active
    }
    
    var forceActive: Int {
        return self.pilotStateData.force_active
    }
    
    var chargeActive: Int {
        return self.pilotStateData.charge_active
    }
    
    var dial: [String] {
        let ship = self.shipPilot.ship
        
        return ship.dial
    }
    
    func update(type: PilotStatePropertyType, active: Int, inactive: Int) {
        switch(type) {
        case .hull:
            updateHull(active: active, inactive: inactive)
        case .shield:
            updateShield(active: active, inactive: inactive)
        case .force:
            updateForce(active: active, inactive: inactive)
        case .charge:
            updateCharge(active: active, inactive: inactive)
        case .shipIDMarker(let id):
            updateShipIDMarker(marker: id)
        case .selectedManeuver(let maneuver):
            updateSelectedManeuver(maneuver: maneuver)
        }
    }
    
    func updateHull(active: Int, inactive: Int) {
            self.pilotStateData.change(update: {
                $0.updateHull(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateShield(active: Int, inactive: Int) {
            self.pilotStateData.change(update: {
                $0.updateShield(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateForce(active: Int, inactive: Int) {
            self.pilotStateData.change(update: {
                $0.updateForce(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateCharge(active: Int, inactive: Int) {
            self.pilotStateData.change(update: {
                $0.updateCharge(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateShipIDMarker(marker: String) {
        self.pilotStateData.change(update: {
            $0.updateShipID(shipID: marker)
            self.updateState(newData: $0)
        })
    }
    
    func updateSelectedManeuver(maneuver: String) {
        print("\(Date()) \(#function) : \(maneuver)")
        self.pilotStateData.change(update: {
            $0.updateManeuver(maneuver: maneuver)
            self.updateState(newData: $0)
        })
    }
    
    func updateState(newData: PilotStateData) {
        print(newData.description)
        
        let json = PilotStateData.serialize(type: newData)
        /// where do we get a PilotState instance????
        guard let state = self.pilotState else { return }
        
        self.pilotStateService.updatePilotState(pilotState: state,
                                                state: json,
                                                pilotIndex: newData.pilot_index)
    }
}

enum PilotStatePropertyType {
    case hull
    case shield
    case charge
    case force
    case shipIDMarker(String)
    case selectedManeuver(String)
}

// MARK:- ShipView
struct ShipView: View {
    struct TextOverlay: View {
        @Binding var isShowing : Bool
    
        var body: some View {
            Text("Charge")
                .frame(width: 100, height: 100)
                .background(Color.yellow)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)
        }
    }

    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    
    @State var showCardOverlay: Bool = false
    @State var showImageOverlay: Bool = false
    @State var imageOverlayUrl: String = ""
    @State var displayOverlay: Bool = false
    @ObservedObject var viewModel: ShipViewModel
    let theme: Theme = WestworldUITheme()
    let printer = DeallocPrinter("ShipView")
    
    init(viewModel: ShipViewModel) {
        self.viewModel = viewModel
        self.currentManeuver = ""
    }

    // MARK:- computed properties
    var body: some View {
        content
    }
    
    var content: some View {
        VStack(alignment: .leading) {
            headerView
            CustomDivider()
            bodyContent
            CustomDivider()
            footer
        }
        .padding()
        .overlay(imageOverlayView)
        .background(theme.BUTTONBACKGROUND)
    }
    
    var headerView: some View {
        HStack {
            HStack(alignment: .top) {
                backButtonView
            }
            .frame(width: 150, height: 50, alignment: .leading)
            //            .border(Color.blue, width: 2)
            
            PilotDetailsView(shipPilot: viewModel.shipPilot,
                             displayUpgrades: true,
                             displayHeaders: false,
                             displayDial: false)
                .padding(2)
            //                .border(Color.green, width: 2)
            
            HStack {
                Text("Reset")
                //            Image(uiImage: UIImage(named: "repeat_new", in: nil, with: regularMediumSymbolConfig)!.withRenderingMode(.alwaysTemplate))
                //                .foregroundColor(.accentColor)
                            
//                Image(systemName: "arrow.clockwise.circle.fill")
                Image(systemName: "repeat")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
            }.padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .top) {
                /// Call .equatable() to prevent refreshing the static image
                /// https://swiftui-lab.com/equatableview/
                ImageView(url: viewModel.shipImageURL,
                         shipViewModel: self.viewModel,
                         label: "ship")
                .equatable()
                .frame(width: 350.0, height:500)
                .onTapGesture { self.showCardOverlay.toggle() }
                .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                .environmentObject(viewModel)
            
                    VStack(spacing: 20) {
                        // Hull
                        if (viewModel.pilotStateData.hullMax > 0) {
                            LinkedView(type: StatButtonType.hull,
                                       active: viewModel.hullActive,
                                       inactive: viewModel.pilotStateData.hullMax - viewModel.hullActive)
                            { (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.hull,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                        
                        // Shield
                        if (viewModel.pilotStateData.shieldsMax > 0) {
                            LinkedView(type: StatButtonType.shield,
                                       active: viewModel.shieldsActive,
                                       inactive: viewModel.pilotStateData.shieldsMax - viewModel.shieldsActive)
                            { (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.shield,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                        
                        // Force
                        if (viewModel.pilotStateData.forceMax > 0) {
                            LinkedView(type: StatButtonType.force,
                                       active: viewModel.forceActive,
                                       inactive: viewModel.pilotStateData.forceMax - viewModel.forceActive)
                            { (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.force,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                        
                        // Charge
                        if (viewModel.pilotStateData.chargeMax > 0) {
                            LinkedView(type: StatButtonType.charge,
                                       active: viewModel.chargeActive,
                                       inactive: viewModel.pilotStateData.chargeMax - viewModel.chargeActive)
                            { (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.charge,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                    }.padding(.top, 20)
//                .border(Color.green, width: 2)

                DialView(temperature: 100,
                     diameter: 400,
                     currentManeuver: self.$viewModel.currentManeuver,
//                    currentManeuver: $currentManeuver.onUpdate{ (maneuver) in
//                        self.viewModel.updateSelectedManeuver(maneuver: maneuver)
//                    //                            self.viewModel.currentManeuver = maneuver
//                    },
                     dial: self.viewModel.shipPilot.ship.dial,
                     displayAngleRanges: false) { (maneuver) in
                        self.viewModel.updateSelectedManeuver(maneuver: maneuver)
                    }
                .frame(width: 400.0,height:400)
//                    .border(theme.BORDER_ACTIVE, width: 2)
            }
    }
    

    
    var footer: some View {
        UpgradesView(upgrades: viewModel.shipPilot.upgrades,
                     showImageOverlay: $showImageOverlay,
                     imageOverlayUrl: $imageOverlayUrl)
            .environmentObject(viewModel)
    }
    
    var backButtonView: some View {
        Button(action: {
            self.viewFactory.back()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Back to Squad")
                    .foregroundColor(theme.TEXT_FOREGROUND)
            }
        }.padding(5)
    }
    
    var clearView: some View {
        Color
            .clear
//            .border(Color.red, width: 5)
    }
    
    
    
    var upgradeImageOverlay: some View {
        ZStack {
            Color
                .gray
                .opacity(0.5)
                .onTapGesture{
                    self.showImageOverlay = false
                    self.viewModel.displayImageOverlay = false
                }
            
            // If the upgrade has two sides...
            /*
             UpgradeCardFlipView(frontURL, backURL)
             */
            ImageView(url: self.imageOverlayUrl,
                      shipViewModel: self.viewModel,
                      label: "upgrade")
                .frame(width: 500.0, height:350)
                .environmentObject(viewModel)
        }
    }
    
    var imageOverlayView: AnyView {
        let defaultView = AnyView(clearView)
        
        print("UpgradeView var imageOverlayView self.showImageOverlay=\(self.showImageOverlay)")
        print("UpgradeView var imageOverlayView self.viewModel.displayImageOverlay=\(self.viewModel.displayImageOverlay)")
        
        if (self.viewModel.displayImageOverlay == true) {
            return AnyView(upgradeImageOverlay)
        } else {
            return defaultView
        }
    }
}



