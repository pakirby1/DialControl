//
//  LinkedViewNew.swift
//  DialControl
//
//  Created by Phil Kirby on 1/19/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//
import Foundation
import SwiftUI
import Combine

struct LinkedViewNew: View {
    let id = UUID()
    var deallocPrinter: DeallocPrinter
    let type: StatButtonType
    let symbolSize: CGFloat = 72
    var viewModel: LinkedViewModel
    
    init(viewModel: LinkedViewModel, type: StatButtonType) {
        deallocPrinter = DeallocPrinter("LinkedView \(id): \(type) viewModel: \(viewModel)")
        self.viewModel = viewModel
        self.type = type
    }
    
    func buildTokenView(isActive: Bool) -> some View {
        ZStack {
            // have to use if instead of switch because it returns some View
            if type == .charge {
                TokenView(symbol: StatButtonType.charge.symbol,
                          color: type.color,
                          isActive: isActive)
            } else if type == .force {
                TokenView(symbol: StatButtonType.force.symbol,
                          color: type.color,
                          isActive: isActive)
            } else if type == .shield {
                TokenView(symbol: StatButtonType.shield.symbol,
                          color: type.color,
                          isActive: isActive)
            } else {
                TokenView(symbol: StatButtonType.hull.symbol,
                          color: type.color,
                          isActive: isActive)
            }
        }
    }
    
    var activeButton: some View {
        func action() {
            self.viewModel.spend(type: self.type)
        }
        
        return Button(action:action)
        {
            buildTokenView(isActive: true)
        }.overlay(CountBannerView(count: self.viewModel.viewProperties.active, type: .active)
            .offset(x: CGFloat(50.0),
                    y: CGFloat(-50)))
    }
    
    var inActiveButton: some View {
        func action() {
            self.viewModel.recover(type: self.type)
        }
        
        return Button(action:action)
        {
            buildTokenView(isActive: false)
        }.overlay(CountBannerView(count: self.viewModel.viewProperties.inactive, type: .inactive).offset(x: 50, y: -50))
    }
    
    var body: some View {
        HStack(spacing: 25) {
            activeButton
            inActiveButton
        }
    }
}

struct TokenView: View {
    let symbol: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        ZStack {
            Image(uiImage: UIImage(named: "Token.Shape") ?? UIImage())
                .resizable()
                .frame(width: 90, height: 90)
                .foregroundColor(Color.black)
            
            if (isActive) {
                Image(uiImage: UIImage(named: "Token.Lines") ?? UIImage())
                    .resizable()
                    .frame(width: 96, height: 96)   // Let the lines just barely overlap shape
                    .foregroundColor(color)
            }
            
            Text(symbol)
                .font(.custom("xwing-miniatures", size: 48))
                .foregroundColor(color)
        }
    }
}

class LinkedViewModel : ObservableObject {
//    let store: Store
    let pilotIndex: Int
    @Published var viewProperties = ViewProperties(active: 0, inactive: 0)
    let type: StatButtonType
    var cancellable: AnyCancellable?
    let shipPilot: ShipPilot
    
    // pilotIndex = ShipViewModel.shipPilot.pilotState.pilotIndex
    init(pilotIndex: Int, type: StatButtonType, shipPilot: ShipPilot) {
//        self.store = store
        self.pilotIndex = pilotIndex
        self.type = type
        self.shipPilot = shipPilot
//        self.cancellable = configureViewProperties()
    }
    
    func spend(type: StatButtonType) {
        // send a ChargeAction(type: ChargeActionType.spend(StatButtonType)
        // to the Store
        let action = ChargeAction(pilotIndex: pilotIndex, type: .spend(type))
//        store.send(action: action)
    }
    
    func recover(type: StatButtonType) {
        // send a ChargeAction(type: ChargeActionType.spend(StatButtonType)
        // to the Store
        let action = ChargeAction(pilotIndex: pilotIndex, type: .recover(type))
//        store.send(action: action)
    }
}

extension LinkedViewModel {
    struct ViewProperties {
        let active: Int
        let inactive: Int
    }
}

//extension LinkedViewModel : ViewPropertyGenerating {
//    func buildViewProperties(state: AppState) -> LinkedViewModel.ViewProperties {
//        // get the psd from the store by pilotIndex & squadIndex
//        guard let psd = state.squadState.shipPilots[pilotIndex].pilotStateData else {
//            return ViewProperties(active: 0, inactive: 0)
//        }
//
//        let active: Int = psd.getActive(type: type)
//        let inactive: Int = psd.getInactive(type: type)
//
//        return ViewProperties(active: active, inactive: inactive)
//    }
//}
