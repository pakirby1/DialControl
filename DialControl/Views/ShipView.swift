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
    private var cancellable: AnyCancellable?
    var pilotStateData: PilotStateData? = nil
    let pilotStateService: PilotStateServiceProtocol
    
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
        
        // CoreData
        self.moc = moc
        self.frc = BindableFetchedResultsController<ImageData>(fetchRequest: ImageData.fetchAll(),
            managedObjectContext: moc)

        // take the stream generated by the frc and @Published fetchedObjects
        // and assign it to
        // players.  This way clients don't have to access viewModel.frc.fetchedObjects
        // directly.  Use $ to geet access to the publisher of the @Published.
        self.cancellable = self.frc
            .$fetchedObjects
            .print()
            .receive(on: DispatchQueue.main)
            .assign(to: \ShipViewModel.images, on: self)
        
        self.loadPilotStateFromCoreData()
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
                _ = pilotStates.map{ print("\(String(describing: $0.id)) shipPilot.pilotStateId \(shipPilot.pilotStateId)") }
                
                let filtered = pilotStates.filter{ $0.id == shipPilot.pilotStateId }
                
                if filtered.count == 1 {
                    guard let state: PilotState = filtered.first else { return }
                    guard let json = state.json else { return }
                    let data: PilotStateData = PilotStateData.deserialize(jsonString: json)
                    self.pilotStateData = data
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
        guard let state = self.pilotStateData else { return 0 }
        return state.shield_active
    }
    
    var hullActive: Int {
//        self.shipPilot.hullStats
        guard let state = self.pilotStateData else { return 0 }
        return state.hull_active
    }
    
    var dial: [String] {
        let ship = self.shipPilot.ship
        
        return ship.dial
    }
    
    var hullMax: Int {
        guard let state = self.pilotStateData else { return 0 }
        return state.hull_active + state.hull_inactive
    }

    var shieldsMax: Int {
        guard let state = self.pilotStateData else { return 0 }
        return state.shield_active + state.shield_inactive
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
        }
    }
    
    func updateHull(active: Int, inactive: Int) {
        if let psd = pilotStateData {
            pilotStateData?.updateHull(active: active, inactive: inactive)
            updateState(newState: psd)
        }
    }
    
    func updateShield(active: Int, inactive: Int) {
        if let _ = pilotStateData {
            self.pilotStateData?.change(update: {
                $0.updateShield(active: active, inactive: inactive)
                self.updateState(newState: $0)
            })
        }
    }
    
    func updateForce(active: Int, inactive: Int) {
        if let _ = pilotStateData {
            self.pilotStateData?.change(update: {
                $0.updateForce(active: active, inactive: inactive)
                self.updateState(newState: $0)
            })
        }
    }
    
    func updateCharge(active: Int, inactive: Int) {
        if let _ = pilotStateData {
            self.pilotStateData?.change(update: {
                $0.updateCharge(active: active, inactive: inactive)
                self.updateState(newState: $0)
            })
        }
    }
    
    func updateShipIDMarker(marker: String) {}
    
    func updateState(newState: PilotStateData) {
        print(newState.description)
        
        let json = PilotStateData.serialize(type: newState)
        /// where do we get a PilotState instance????
//        self.pilotStateService.updatePilotState(pilotState: newState,
//                                                state: json,
//                                                pilotIndex: newState.pilot_index)
    }
}

enum PilotStatePropertyType {
    case hull
    case shield
    case charge
    case force
    case shipIDMarker(String)
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
    let viewModel: ShipViewModel
    let theme: Theme = WestworldUITheme()
    let printer = DeallocPrinter("ShipView")
    
    init(viewModel: ShipViewModel) {
        self.viewModel = viewModel
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
                             displayHeaders: false)
                .padding(2)
            //                .border(Color.green, width: 2)
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .top) {
                ImageView(url: viewModel.shipImageURL,
                             shipViewModel: self.viewModel,
                             label: "ship")
                    .frame(width: 350.0, height:500)
                    .onTapGesture { self.showCardOverlay.toggle() }
                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                    .environmentObject(viewModel)
            
                    VStack(spacing: 20) {
                        if (viewModel.hullActive > 0) {
                            LinkedView(type: StatButtonType.hull,
                                       active: viewModel.hullActive,
                                       inactive: viewModel.hullMax - viewModel.hullActive)
                            { (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.hull,
                                                      active: active,
                                                      inactive: inactive)
                            }
                            
//                            LinkedView(maxCount: viewModel.hullMax, type: StatButtonType.hull) { (active, inactive) in
//                                self.viewModel.update(type: PilotStatePropertyType.hull,
//                                                      active: active,
//                                                      inactive: inactive)
//                            }
                        }
                        
                        if (viewModel.shieldsActive > 0) {
                            LinkedView(maxCount: viewModel.shieldsMax, type: StatButtonType.shield){ (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.shield,                          active: active,
                                                      inactive: inactive)
                            }
                        }
                        
                        if (viewModel.force > 0) {
                            LinkedView(maxCount: viewModel.force, type: StatButtonType.force){ (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.force,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                        
                        if (viewModel.charges > 0) {
                            LinkedView(maxCount: viewModel.charges, type: StatButtonType.charge){ (active, inactive) in
                                self.viewModel.update(type: PilotStatePropertyType.charge,
                                                      active: active,
                                                      inactive: inactive)
                            }
                        }
                    }.padding(.top, 20)
//                .border(Color.green, width: 2)

                DialView(temperature: 0,
                     diameter: 400,
                     currentManeuver: $currentManeuver,
                     dial: self.viewModel.shipPilot.ship.dial,
                     displayAngleRanges: false)
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



