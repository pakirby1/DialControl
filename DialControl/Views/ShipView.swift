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
    @Published var pilotStateData: PilotStateData
    let pilotStateService: PilotStateServiceProtocol
    var pilotState: PilotState? = nil
    @Published var currentManeuver: String = ""

    // CoreData
    private let frc: BindableFetchedResultsController<ImageData>
    var moc: NSManagedObjectContext
    
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
        
        self.frc
            .$fetchedObjects
            .print()
            .receive(on: DispatchQueue.main)
            .assign(to: \ShipViewModel.images, on: self)
            .store(in: &cancellableSet)
        
        self.$currentManeuver
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .print("Hello")
            .receive(on: DispatchQueue.main)
            .lane("currentManeuver")
            .sink(receiveValue: {
                self.updateSelectedManeuver(maneuver: $0)
                
                if !self.pilotStateData.isDestroyed {
                    self.updateDialStatus(status: .set)
                }
            })
            .store(in: &cancellableSet)
    }

    lazy var shipImageURL: String = {
        loadShipFromJSON(shipName: shipPilot.shipName,
                       pilotName: shipPilot.pilotName).1.image
    }()
    
    /// What do we return if we encounter an error (empty file)?
    /// This should be removed,  go through the JSONService, or better yet, the Store
    func loadShipFromJSON(shipName: String, pilotName: String) -> (Ship, Pilot) {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        shipJSON = getJSONFor(ship: shipName, faction: squad.faction)
        
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        var foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0].asPilot()
        
        /// Update image to point to "https://pakirby1.github.io/Images/XWing/Pilots/{pilotName}.png
        foundPilots.image = ImageUrlTemplates.buildPilotUrl(xws: pilotName)
        
        return (ship, foundPilots)
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
    
    func handleDestroyed() {
        let current = pilotStateData.dial_status
        
        if pilotStateData.isDestroyed {
            updateDialStatus(status: .destroyed)
        } else {
            updateDialStatus(status: current)
        }
    }
    
    func update(type: PilotStatePropertyType, active: Int, inactive: Int) {
        func old() {
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
            case .upgradeCharge(var upgrade):
//                upgrade.updateCharge(active: active, inactive: inactive)
                updateUpgradeCharge(upgrade: upgrade, active: active, inactive: inactive)
            case .selectedSide(var upgrade, let side):
                updateUpgradeSelectedSide(upgrade: upgrade, selectedSide: side)
            case .reset:
                reset()
            }
        }
        
        func new() {
            switch(type) {
            case .hull:
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.hull(active, inactive)))
            case .shield:
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.shield(active, inactive)))
            case .force:
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.force(active, inactive)))
            case .charge:
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.charge(active, inactive)))
            case .shipIDMarker(let id):
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.shipIDMarker(id)))
            case .selectedManeuver(let maneuver):
                updateState(newData: self.pilotStateData.update(type: PilotStatePropertyType_New.selectedManeuver(maneuver)))
            case .upgradeCharge(var upgrade):
                upgrade.updateCharge(active: active, inactive: inactive)
            case .selectedSide(let side):
                reset()
            case .reset:
                reset()
            }
        }
        
        old()
//        new()
    }
    
    func updateUpgradeCharge(upgrade: UpgradeStateData, active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            upgrade.change(update: { newUpgrade in
                print("PAK_\(#function) pilotStateData.id: \(newUpgrade)")
                newUpgrade.updateCharge(active: active, inactive: inactive)
                
                // the old upgrade state is in the pilotStateData, so we need
                // to replace the old upgrade state with the new upgrade state
                // in $0
                if let upgrades = self.pilotStateData.upgradeStates {
                    if let indexOfUpgrade = upgrades.firstIndex(where: { $0.xws == newUpgrade.xws }) {
                        self.pilotStateData.upgradeStates?[indexOfUpgrade] = newUpgrade
                    }
                }
                
                self.updateState(newData: self.pilotStateData)
            })
    }
    
    func updateUpgradeSelectedSide(upgrade: UpgradeStateData,
                                   selectedSide: Bool)
    {
        print("\(Date()) PAK_\(#function) : side: \(selectedSide)")
            upgrade.change(update: { newUpgrade in
                print("PAK_\(#function) pilotStateData.id: \(newUpgrade)")
                newUpgrade.updateSelectedSide(side: selectedSide ? 1 : 0)
                
                // the old upgrade state is in the pilotStateData, so we need
                // to replace the old upgrade state with the new upgrade state
                // in $0
                if let upgrades = self.pilotStateData.upgradeStates {
                    if let indexOfUpgrade = upgrades.firstIndex(where: { $0.xws == newUpgrade.xws }) {
                        self.pilotStateData.upgradeStates?[indexOfUpgrade] = newUpgrade
                    }
                }
                
                self.updateState(newData: self.pilotStateData)
            })
    }
    
    func reset() {
        print("\(Date()) PAK_(#function): \(self.pilotStateData.description)")
    
        self.pilotStateData.mutate(update: {
            $0.reset()
            self.updateState(newData: $0)
            print("\(Date()) PAK_(#function): \(self.pilotStateData.description)")
        })
    }
    
    func updateHull(active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            self.pilotStateData.mutate(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateHull(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateShield(active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            self.pilotStateData.mutate(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateShield(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateForce(active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            self.pilotStateData.mutate(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateForce(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateCharge(active: Int, inactive: Int) {
        print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
            self.pilotStateData.mutate(update: {
                print("PAK_\(#function) pilotStateData.id: \($0)")
                $0.updateCharge(active: active, inactive: inactive)
                self.updateState(newData: $0)
            })
    }
    
    func updateShipIDMarker(marker: String) {
        print("\(Date()) \(#function) : \(marker)")
        self.pilotStateData.mutate(update: {
            $0.updateShipID(shipID: marker)
            self.updateState(newData: $0)
        })
    }
    
    func updateSelectedManeuver(maneuver: String) {
        print("\(Date()) \(#function) : \(maneuver)")
        self.pilotStateData.mutate(update: {
            $0.updateManeuver(maneuver: maneuver)
            self.updateState(newData: $0)
        })
    }
    
    func updateDialStatus(status: DialStatus) {
        print("\(Date()) \(#function) : \(status)")
        self.pilotStateData.mutate(update: {
            $0.updateDialStatus(status: status)
            self.updateState(newData: $0)
        })
    }
    
    func updateState(newData: PilotStateData) {
        print("\(Date()) PAK_updateState: \(newData.description)")
        
        let json = PilotStateData.serialize(type: newData)
        /// where do we get a PilotState instance????
        guard let state = self.pilotState else { return }
        
        self.pilotStateService.updatePilotState(pilotState: state,
                                                state: json,
                                                pilotIndex: newData.pilot_index)
        
        self.pilotStateData = newData
    }
    
    func updateState_New(newData: PilotStateData) {
        guard let state = self.pilotState else { return }
        
        self.pilotStateService.updateState(newData: newData,
                                           state: state)
        
        self.pilotStateData = newData
    }
    
    func getUpgradeStateData(upgrade: Upgrade) -> UpgradeStateData? {
        // do we have any upgrade states?
        guard let upgradeStates = self.pilotStateData.upgradeStates else { return nil }
        
        let upgradeStateData: [UpgradeStateData] = upgradeStates.filter({ upgradeState in upgradeState.xws == upgrade.xws })
    
        // yes, return the upgrade state with matching name/xws or nil
        return (upgradeStateData.count > 0 ? upgradeStateData[0] : nil)
    }
}

enum PilotStatePropertyType {
    case hull
    case shield
    case charge
    case force
    case shipIDMarker(String)
    case selectedManeuver(String)
    case upgradeCharge(UpgradeStateData)
    case reset
    case selectedSide(UpgradeStateData, Bool)
}

enum PilotStatePropertyType_New {
    case hull(Int, Int)
    case shield(Int, Int)
    case charge(Int, Int)
    case force(Int, Int)
    case shipIDMarker(String)
    case selectedManeuver(String)
    case revealAllDials(Bool)
    case hasSystemPhaseAction(Bool)
}

// MARK:- ShipView
struct ShipView: View {
    struct SelectedUpgrade {
        let upgrade: Upgrade
        let imageOverlayUrl: String
        let imageOverlayUrlBack: String
    }

    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    @State var showImageOverlay: Bool = false
    @State var imageOverlayUrl: String = ""
    @State var imageOverlayUrlBack: String = ""
    @ObservedObject var viewModel: ShipViewModel
    let theme: Theme = WestworldUITheme()
    let printer = DeallocPrinter("ShipView")
    @State var selectedUpgrade: UpgradeView.UpgradeViewModel? = nil
    
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
            CustomDivider().border(Color.green)
//            bodyContent
            bodyContent
            CustomDivider().border(Color.green)
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
            
            PilotDetailsView(viewModel: PilotDetailsViewModel(shipPilot: self.viewModel.shipPilot, pilotStateService: self.viewModel.pilotStateService),
                     displayUpgrades: true,
                     displayHeaders: false,
                     displayDial: false)
                .border(Color.green)
                .padding(2)
            //                .border(Color.green, width: 2)
            
            VectorImageButton(imageName: "Reset", size: CGSize(width: 40, height: 60)){
                self.viewModel.update(type: .reset,
                                      active: 0,
                                      inactive: 0)
            }
        }
    }
    
    var dialStatusText: String {
        return "\(self.viewModel.pilotStateData.dial_status.description)"
    }
    
    func buildLinkedView(max: Int,
                         type: StatButtonType,
                         active: Int,
                         inActive: Int,
                         updateType: PilotStatePropertyType,
                         handleDestroyed: Bool = false) -> AnyView
    {
        if (max > 0) {
            return AnyView(LinkedView(type: type,
                                      active: active,
                                      inactive: inActive)
            { (active, inactive) in
                self.viewModel.update(type: updateType,
                                      active: active,
                                      inactive: inactive)
                
                if (handleDestroyed) {
                    self.viewModel.handleDestroyed()
                }
            })
        }
        
        return AnyView(EmptyView())
    }
    
    var footer: some View {
        UpgradesView(upgrades: viewModel.shipPilot.upgrades,
                     showImageOverlay: $showImageOverlay,
                     imageOverlayUrl: $imageOverlayUrl,
                     imageOverlayUrlBack: $imageOverlayUrlBack,
                     selectedUpgrade: $selectedUpgrade)
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
    }
    
    var upgradeImageOverlay: some View {
        ZStack {
            Color
                .gray
                .opacity(0.5)
                .onTapGesture{
                    self.showImageOverlay = false
                }
            
            // If the upgrade has two sides...
            /*
             UpgradeCardFlipView(frontURL, backURL)
             */
            upgradeCardImage
            
            linkedView
            
//            LinkedView(type: StatButtonType.charge,
//                       active: 1,
//                       inactive: 1)
//            { (active, inactive) in
////                           self.viewModel.update(type: PilotStatePropertyType.charge,
////                                                 active: active,
////                                                 inactive: inactive)
//            }.offset(x:0, y:250)
        }
    }
    
    
    
    var linkedView: AnyView {
        let emptyView = AnyView(EmptyView())
        
        // Do we hava a selectedUpgrade?
            // no, return
            guard let selectedUpgrade = self.selectedUpgrade else { return emptyView }
        
            // yes
                // do we have an upgradeState for this upgrade?
            guard let upgradeState = viewModel.getUpgradeStateData(upgrade: selectedUpgrade.upgrade) else { return emptyView }
        
            guard let charge_active = upgradeState.charge_active else { return emptyView }
            guard let charge_inactive = upgradeState.charge_inactive else { return emptyView }
        
            return AnyView(LinkedView(type: StatButtonType.charge,
                                      active: charge_active,
                                      inactive: charge_inactive)
            { (active, inactive) in
                // update the values for upgradeState
                /*
                 self.viewModel.update(type: PilotStatePropertyType.charge,
                 active: active,
                 inactive: inactive)
                 */
                self.viewModel.update(
                    type: PilotStatePropertyType.upgradeCharge(upgradeState),
                    active: active,
                    inactive: inactive)
            }.offset(x:0, y:250))
    }
    
    var upgradeCardImage: AnyView {
        let emptyView = AnyView(EmptyView())
        
        var ret = AnyView(ImageView(url: self.imageOverlayUrl,
                                    moc: self.viewModel.moc,
              label: "upgrade")
        .frame(width: 500.0, height:350)
        .environmentObject(viewModel))
        
        if (self.imageOverlayUrlBack != "") {
            guard let selectedUpgrade = self.selectedUpgrade else { return emptyView }
            
            guard let upgradeState = self.viewModel.getUpgradeStateData(upgrade: selectedUpgrade.upgrade) else { return emptyView }
            let side = (upgradeState.selected_side == 0) ? false : true
            
//            let flipView = UpgradeCardFlipView(
//                side: side,
//                frontUrl: self.imageOverlayUrl,
//                backUrl: self.imageOverlayUrlBack,
//                viewModel: self.viewModel,
//                update: { side in
//                    self.viewModel.update(
//                        type: PilotStatePropertyType.selectedSide(upgradeState,
//                                                                  side), active: -1, inactive: -1
//                    )
//                })
            
            
//            ret = flipView
//                .eraseToAnyView()
            
            ret = EmptyView().eraseToAnyView()
        }
        
        return ret
    }
    
    var imageOverlayView: AnyView {
        let defaultView = AnyView(clearView)
        
        print("UpgradeView var imageOverlayView self.showImageOverlay=\(self.showImageOverlay)")

        if (self.showImageOverlay == true) {
            return AnyView(upgradeImageOverlay)
        } else {
            return defaultView
        }
    }
}

extension ShipView {
    var setDialButton: some View {
        Text("Set")
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
            .onTapGesture {
                if self.viewModel.pilotStateData.isDestroyed {
                    self.viewModel.updateDialStatus(status: .destroyed)
                } else {
//                    self.viewModel.updateSelectedManeuver(maneuver: "")
                    self.viewModel.updateDialStatus(status: .set)
                }
            }
    }
    
    var setIonManeuverButton: some View {
        Text("Ion")
            .foregroundColor(.red)
            .font(.largeTitle)
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
        )
        .onTapGesture {
            if self.viewModel.pilotStateData.isDestroyed {
                self.viewModel.updateDialStatus(status: .destroyed)
            } else {
//                self.viewModel.updateSelectedManeuver(maneuver: "1FB")
                self.viewModel.updateDialStatus(status: .ionized)
            }
        }
    }
    
    var bodyContent: some View {
            HStack(alignment: .top) {
                    /// Call .equatable() to prevent refreshing the static image
                    /// https://swiftui-lab.com/equatableview/
                    ImageView(url: viewModel.shipImageURL,
                              moc: self.viewModel.moc,
                             label: "ship")
                    .equatable()
                    .frame(width: 350.0, height:500)
                    .environmentObject(viewModel)
                
                        VStack(spacing: 20) {
                            // Hull
                            buildLinkedView(max: viewModel.pilotStateData.hullMax,
                                            type: StatButtonType.hull,
                                            active: viewModel.hullActive,
                                            inActive: viewModel.pilotStateData.hullMax - viewModel.hullActive,
                                            updateType: PilotStatePropertyType.hull,
                                            handleDestroyed: true)
                            
                            // Shield
                            buildLinkedView(max: viewModel.pilotStateData.shieldsMax,
                                            type: StatButtonType.shield,
                                            active: viewModel.shieldsActive,
                                            inActive: viewModel.pilotStateData.shieldsMax - viewModel.shieldsActive,
                                            updateType: PilotStatePropertyType.shield,
                                            handleDestroyed: true)

                            // Force
                            buildLinkedView(max: viewModel.pilotStateData.forceMax,
                                            type: StatButtonType.force,
                                            active: viewModel.forceActive,
                                            inActive: viewModel.pilotStateData.forceMax - viewModel.forceActive,
                                            updateType: PilotStatePropertyType.force)

                            // Charge
                            buildLinkedView(max: viewModel.pilotStateData.chargeMax,
                                            type: StatButtonType.charge,
                                            active: viewModel.chargeActive,
                                            inActive: viewModel.pilotStateData.chargeMax - viewModel.chargeActive,
                                            updateType: PilotStatePropertyType.charge)
                            
                            Text("Dial Status: \(dialStatusText)")
                        }.padding(.top, 20)
    //                .border(Color.green, width: 2)

                    VStack {
                        DialView(temperature: 100,
                                             diameter: 400,
                                             currentManeuver: self.$viewModel.currentManeuver,
                                             dial: self.viewModel.shipPilot.ship.dial,
                                             displayAngleRanges: false)
                        { (maneuver) in
                            self.viewModel.updateSelectedManeuver(maneuver: maneuver)
                        }
                        .frame(width: 400.0,height:400)
                        
                        if (self.viewModel.currentManeuver != "") {
                            HStack {
                                setDialButton
                                setIonManeuverButton
                            }
                        }
                    }
                }
        }
}

