//
//  Redux_ShipView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/26/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//
import Foundation
import SwiftUI
import Combine
import TimelaneCombine
import CoreData

extension ShipViewModel : ShipViewModelProtocol {}
extension Redux_ShipViewModel : ShipViewModelProtocol {}

/*
 Since we cannot use protocols with @ObservedObject property wrapper
 we can do this:
 https://stackoverflow.com/questions/59503399/how-to-define-a-protocol-as-a-type-for-a-observedobject-property
 */
protocol ShipViewModelProtocol: ObservableObject {
    // Put into Environment
    var moc: NSManagedObjectContext { get set }
    var pilotStateService: PilotStateServiceProtocol { get }
    
    var shipPilot: ShipPilot { get set }
    var pilotStateData: PilotStateData { get set }
    var currentManeuver: String { get set }
    var shipImageURL: String { get set }
    
    var hullActive: Int { get }
    var chargeActive: Int { get }
    var forceActive: Int { get }
    var shieldsActive: Int { get }
    
    func update(type: PilotStatePropertyType, active: Int, inactive: Int)
    func handleDestroyed()
    func updateSelectedManeuver(maneuver: String)
    func updateDialStatus(status: DialStatus)
}

// MARK:- ShipViewModel
class Redux_ShipViewModel: ObservableObject {
    var shipPilot: ShipPilot
    var squad: Squad
    
    // Streams
    @Published var pilotStateData: PilotStateData
    @Published var shipImageURL: String = ""
    @Published var shipImage: UIImage = UIImage()
    @Published var upgradeImage: UIImage = UIImage()
    @Published var currentManeuver: String = ""
    @Published var images: [ImageData] = []
    
    @ObservedObject var store: MyAppStore
    
    private var _displayImageOverlay: Bool = false
    private var cancellableSet = Set<AnyCancellable>()
    
    let pilotStateService: PilotStateServiceProtocol
    var pilotState: PilotState? = nil

    // CoreData
    private let frc: BindableFetchedResultsController<ImageData>
    var moc: NSManagedObjectContext
    
    // Images Support
//    @ObservedObject var networkCacheViewModel: NetworkCacheViewModel
    
    init(moc: NSManagedObjectContext,
         shipPilot: ShipPilot,
         squad: Squad,
         pilotStateService: PilotStateServiceProtocol,
         store: MyAppStore)
    {
        self.shipPilot = shipPilot
        self.squad = squad
        self.pilotStateService = pilotStateService
        self.pilotStateData = shipPilot.pilotStateData!
        self.pilotState = shipPilot.pilotState
        self.store = store
        
        
        
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
        
        // Init
        self.initState()
        self.fetchImageURL()
        
        self.frc
            .$fetchedObjects
            .print()
            .receive(on: DispatchQueue.main)
            .assign(to: \.images, on: self)
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
        
        self.store
            .$state
            .lane("state")
            .sink(receiveValue: {
                self.pilotStateData = $0.ship.pilotStateData!
                self.shipImageURL = $0.ship.shipImageURL
                
                print("PAKRedux_ShipView")
                print(self.pilotStateData)
                print(self.shipImageURL)
            })
            .store(in: &cancellableSet)
    }

    func initState() {
        self.store.send(.ship(action: .initState(
            shipPilot.pilotStateData!,
            shipPilot.pilotState
        )))
    }
    
    func fetchImageURL() {
        self.store.send(.ship(action: .loadShipImage(
            shipPilot.shipName,
            shipPilot.pilotName,
            self.squad
        )))
    }
    
//    lazy var shipImageURL: String = {
//        self.store.send(.ship(action: .loadShipImage(
//            shipPilot.shipName,
//            shipPilot.pilotName,
//            self.squad
//        )))
//
//        return self.store.state.ship.shipImageURL
////        loadShipFromJSON(shipName: shipPilot.shipName,
////                       pilotName: shipPilot.pilotName).1.image
//    }()
    
    
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
    
    var shipId: String {
        return self.pilotStateData.shipID
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
        func Redux_store() {
            switch(type) {
                case .hull:
                    self.store.send(.ship(action: .updateHull(active, inactive)))
                case .shield:
                    self.store.send(.ship(action: .updateShield(active, inactive)))
                case .force:
                    self.store.send(.ship(action: .updateForce(active, inactive)))
                case .charge:
                    self.store.send(.ship(action: .updateCharge(active, inactive)))
                case .shipIDMarker(let id):
                    self.store.send(.ship(action: .updateShipIDMarker(id)))
                case .selectedManeuver(let maneuver):
                    self.store.send(.ship(action: .updateSelectedManeuver(maneuver)))
                case .upgradeCharge(var upgrade):
                    self.store.send(.ship(action: .updateUpgradeCharge(upgrade, active, inactive)))
                case .selectedSide(var upgrade, let side):
                    self.store.send(.ship(action: .updateUpgradeSelectedSide(upgrade, side)))
                case .reset:
                    self.store.send(.ship(action: .reset))
            }
        }
        
        func old() {
            func updateHull(active: Int, inactive: Int) {
                print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
                    self.pilotStateData.change(update: {
                        print("PAK_\(#function) pilotStateData.id: \($0)")
                        $0.updateHull(active: active, inactive: inactive)
                        self.updateState(newData: $0)
                    })
            }
            
            func updateShield(active: Int, inactive: Int) {
                print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
                    self.pilotStateData.change(update: {
                        print("PAK_\(#function) pilotStateData.id: \($0)")
                        $0.updateShield(active: active, inactive: inactive)
                        self.updateState(newData: $0)
                    })
            }
            
            func updateForce(active: Int, inactive: Int) {
                print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
                    self.pilotStateData.change(update: {
                        print("PAK_\(#function) pilotStateData.id: \($0)")
                        $0.updateForce(active: active, inactive: inactive)
                        self.updateState(newData: $0)
                    })
            }
            
            func updateCharge(active: Int, inactive: Int) {
                print("\(Date()) PAK_\(#function) : active: \(active) inactive: \(inactive)")
                    self.pilotStateData.change(update: {
                        print("PAK_\(#function) pilotStateData.id: \($0)")
                        $0.updateCharge(active: active, inactive: inactive)
                        self.updateState(newData: $0)
                    })
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
            
            func updateShipIDMarker(marker: String) {
                print("\(Date()) \(#function) : \(marker)")
                self.pilotStateData.change(update: {
                    $0.updateShipID(shipID: marker)
                    self.updateState(newData: $0)
                })
            }
            
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
        
//        old()
        Redux_store()
//        new()
    }
    
    func reset() {
        print("\(Date()) PAK_(#function): \(self.pilotStateData.description)")
    
        self.pilotStateData.change(update: {
            $0.reset()
            self.updateState(newData: $0)
            print("\(Date()) PAK_(#function): \(self.pilotStateData.description)")
        })
    }
    
    func updateSelectedManeuver(maneuver: String) {
        self.store.send(.ship(action: .updateSelectedManeuver(maneuver)))
    }

    func updateDialStatus(status: DialStatus) {
        self.store.send(.ship(action: .updateDialStatus(status)))
    }
    
    func updateShipID(shipId: String) {
        self.store.send(.ship(action: .updateShipIDMarker(shipId)))
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
    
//    func updateState_New(newData: PilotStateData) {
//        guard let state = self.pilotState else { return }
//
//        self.pilotStateService.updateState(newData: newData,
//                                           state: state)
//
//        self.pilotStateData = newData
//    }
}

enum Redux_PilotStatePropertyType {
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

enum Redux_PilotStatePropertyType_New {
    case hull(Int, Int)
    case shield(Int, Int)
    case charge(Int, Int)
    case force(Int, Int)
    case shipIDMarker(String)
    case selectedManeuver(String)
    case revealAllDials(Bool)
}

// MARK:- ShipView
/*
Since we cannot use protocols with @ObservedObject property wrapper
we can do this:
 - specify the @ObservedObject type as a generic type that adopts
   Redux_ShipViewModelProtocol
https://stackoverflow.com/questions/59503399/how-to-define-a-protocol-as-a-type-for-a-observedobject-property
*/
struct Redux_ShipView: View, ShipIDRepresentable {
    
    
//    struct SelectedUpgrade {
//        let upgrade: Upgrade
//        let imageOverlayUrl: String
//        let imageOverlayUrlBack: String
//    }

    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    @State var currentManeuver: String = ""
    @State var showImageOverlay: Bool = false
    @State var imageOverlayUrl: String = ""
    @State var imageOverlayUrlBack: String = ""
//    @ObservedObject var viewModel: Model
    @ObservedObject var viewModel: Redux_ShipViewModel
    let theme: Theme = WestworldUITheme()
    let printer = DeallocPrinter("ShipView")
    @State var selectedUpgrade: UpgradeView.UpgradeViewModel? = nil
    @State var displaySetShipID: Bool = false
    @State var textEntered: String = ""
    
    init(viewModel: Redux_ShipViewModel) {
        self.viewModel = viewModel
        self.currentManeuver = ""
    }

    // MARK:- computed properties
    var shipPilot: ShipPilot {
        viewModel.shipPilot
    }
    
    var customAlert: some View {
        CustomAlert(
            title: "Set Ship ID",
            textInputLabel: "Ship ID",
            textEntered: $textEntered,
            showingAlert: $displaySetShipID)
        {
            self.viewModel.updateShipID(shipId: textEntered)
        }
    }
    
    var body: some View {
        var content: some View {
            var headerView: some View {
                var backButtonView: some View {
                    Button(action: {
                        self.viewFactory.back()
                    }) {
                        HStack {
                            BackButtonView().environmentObject(viewFactory)
                        }
                    }.padding(5)
                }
                
                return HStack {
                    HStack(alignment: .top) {
                        backButtonView
                    }
                    .frame(width: 150, height: 50, alignment: .leading)
                    //            .border(Color.blue, width: 2)
                    
                    shipID
                    
                    PilotDetailsView(viewModel: PilotDetailsViewModel(shipPilot: self.viewModel.shipPilot, pilotStateService: self.viewModel.pilotStateService),
                             displayUpgrades: true,
                             displayHeaders: false,
                             displayDial: false)
                        
                        .padding(2)
                    //                .border(Color.green, width: 2)
                    
                    ResetButton{
                        self.viewModel.update(type: .reset,
                                              active: 0,
                                              inactive: 0)
                    }
                }
            }
            
            var footer: some View {
                UpgradesView(upgrades: viewModel.shipPilot.upgrades,
                             showImageOverlay: $showImageOverlay,
                             imageOverlayUrl: $imageOverlayUrl,
                             imageOverlayUrlBack: $imageOverlayUrlBack,
                             selectedUpgrade: $selectedUpgrade)
                    .environmentObject(viewModel)
            }
            
            return VStack(alignment: .leading) {
                headerView
                CustomDivider()
                bodyContent
                CustomDivider()
                footer
            }
            .padding()
            .overlay(imageOverlayView)
            .background(theme.BUTTONBACKGROUND)
            .popup(isPresented: displaySetShipID, alignment: .center, content: { customAlert })
        }
        
        return content
    }

    var imageOverlayView: AnyView {
        var upgradeLinkedView: AnyView {
            let emptyView = AnyView(EmptyView())
            
            // Do we hava a selectedUpgrade?
            // no, return
            guard let selectedUpgrade = self.selectedUpgrade else { return emptyView }
            
            // yes
            // do we have an upgradeState for this upgrade?
            guard let upgradeState = getUpgradeStateData(upgrade: selectedUpgrade.upgrade) else { return emptyView }
            
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
            )
            
            if (self.imageOverlayUrlBack != "") {
                guard let selectedUpgrade = self.selectedUpgrade else { return emptyView }
                
                guard let upgradeState = getUpgradeStateData(upgrade: selectedUpgrade.upgrade) else { return emptyView }
                
                ret =
                    UpgradeCardFlipView(
                        side: (upgradeState.selected_side == 0) ? false : true,
                        frontUrl: self.imageOverlayUrl,
                        backUrl: self.imageOverlayUrlBack,
                        viewModel: self.viewModel) { side in
                            self.viewModel.update(
                                type: PilotStatePropertyType.selectedSide(upgradeState,
                                                                          side), active: -1, inactive: -1
                            )
                    }.eraseToAnyView()
            }
            
            return ret
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
                
                upgradeLinkedView
            }
        }
        
        let defaultView = AnyView(Color.clear)
        
        print("UpgradeView var imageOverlayView self.showImageOverlay=\(self.showImageOverlay)")

        if (self.showImageOverlay == true) {
            return AnyView(upgradeImageOverlay)
        } else {
            return defaultView
        }
    }
}

extension Redux_ShipView {
    func getUpgradeStateData(upgrade: Upgrade) -> UpgradeStateData? {
        // do we have any upgrade states?
        guard let upgradeStates = viewModel.pilotStateData.upgradeStates else { return nil }
        
        let upgradeStateData: [UpgradeStateData] = upgradeStates.filter({ upgradeState in upgradeState.xws == upgrade.xws })
    
        // yes, return the upgrade state with matching name/xws or nil
        return (upgradeStateData.count > 0 ? upgradeStateData[0] : nil)
    }
    
    func buildLinkedView(max: Int,
                         type: StatButtonType,
                         active: Int,
                         inActive: Int,
                         updateType: PilotStatePropertyType,
                         handleDestroyed: Bool = false) -> AnyView {
        
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
    
    var bodyContent: some View {
        var shipImageView: some View {
            /// Call .equatable() to prevent refreshing the static image
            /// https://swiftui-lab.com/equatableview/
            ImageView(url: viewModel.shipImageURL,
                      moc: self.viewModel.moc,
                     label: "ship")
            .equatable()
            .frame(width: 350.0, height:500)
            .environmentObject(viewModel)
        }
        
        var statusView: some View {
            var dialStatusText: String {
                return "\(self.viewModel.pilotStateData.dial_status.description)"
            }
                
            return VStack(spacing: 20) {
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
                
                VStack {
                    Button("Set Ship ID") {
                        self.displaySetShipID.toggle()
                    }
                    Text("Ship ID: \(textEntered)")
                }
            }.padding(.top, 20)
            //                    .border(Color.green, width: 2)
        }
        
        var dialView: some View {
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
                        self.viewModel.updateSelectedManeuver(maneuver: "1FB")
                        self.viewModel.updateDialStatus(status: .ionized)
                    }
                }
            }
            
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
            
            return VStack {
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
        
        return HStack(alignment: .top) {
            shipImageView
            statusView
            dialView
        }
    }
}

struct CustomAlert: View {
    let title: String
    let textInputLabel: String
    @Binding var textEntered: String
    @Binding var showingAlert: Bool
    let background = Color(UIColor.systemBackground)
    let textColor = Color(UIColor.label)
    let handler: () -> ()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(background)
            VStack {
                Text(title)
                    .font(.title)
                    .foregroundColor(textColor)
                
                Divider()
                
                TextField(textInputLabel, text: $textEntered)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(textColor)
                    .padding(.horizontal, 20)
                    
                    
                Divider()
                
                HStack {
                    Button("OK") {
                        handler()
                        self.showingAlert.toggle()
                    }
                }
                .padding(30)
                .padding(.horizontal, 40)
            }
        }
        .frame(width: 200, height: 150)
    }
}
