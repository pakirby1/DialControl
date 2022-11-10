//
//  UpgradesView.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

// MARK:- UpgradesView
struct UpgradesView: View {
    @EnvironmentObject var viewModel: Redux_ShipViewModel
    @State var imageName: String = ""
    let upgrades: [Upgrade]
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    @Binding var imageOverlayUrlBack: String
    @Binding var selectedUpgrade: UpgradeView.UpgradeViewModel?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades) {
                    UpgradeView(viewModel: UpgradeView.UpgradeViewModel(upgrade: $0))
                    { upgradeViewModel in
                        self.showImageOverlay = true
                        self.imageOverlayUrl = upgradeViewModel.imageUrl
                        self.imageOverlayUrlBack = upgradeViewModel.imageUrlBack
                        self.selectedUpgrade = upgradeViewModel
                    }
                    .environmentObject(viewModel)
                }
            }
        }
    }
}

// MARK:- UpgradeView
/*
 Update to support quick builds (Battle of Yavin)
 */
struct UpgradeView: View {
    struct UpgradeViewModel {
        let upgrade: Upgrade
        
        var imageUrl: String {
            var imageUrl = ""
            
            let type = upgrade.sides[0].type.lowercased() + ".json"
            
            let newType = type.replacingOccurrences(of: " ", with: "-")
            
            let jsonString = loadJSON(fileName: newType, directoryPath: "upgrades")
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
            let matches = upgrades.filter({ $0.xws == upgrade.xws })
            
            if (matches.count > 0) {
                let sides = matches[0].sides
                
                if (sides.count > 0) {
                    imageUrl = ImageUrlTemplates.buildPilotUpgradeFront(xws: upgrade.xws)
                }
            }
            
            return imageUrl
        }
        
        var imageUrlBack: String {
            var imageUrl = ""
            
            let numSides = upgrade.sides.count
            
            if (numSides > 1) {
                let type = upgrade.sides[1].type.lowercased() + ".json"
                
                let newType = type.replacingOccurrences(of: " ", with: "-")
                
                let jsonString = loadJSON(fileName: newType, directoryPath: "upgrades")
                
                let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
                
                let matches = upgrades.filter({ $0.xws == upgrade.xws })
                
                if (matches.count > 0) {
                    let sides = matches[0].sides
                    
                    if (sides.count > 1) {
                        imageUrl = ImageUrlTemplates.buildPilotUpgradeBack(xws: upgrade.xws)
                    }
                }
            }
            
            return imageUrl
        }
    }
    
    let viewModel: UpgradeViewModel
    @EnvironmentObject var shipViewModel: Redux_ShipViewModel
    var callback: (UpgradeViewModel) -> ()
    
    var emptyView: AnyView {
        AnyView(EmptyView())
    }
    
    var banner: AnyView {
        func buildColor(charge_active: Int, charge_inactive: Int, charge_total: Int) -> Color
        {
            if charge_active == charge_total {
                return .green
            } else if (charge_active > 0) && (charge_active < charge_total) {
                return .yellow
            } else {
                return .red
            }
        }
        
        guard let upgradeState = self.shipViewModel.getUpgradeStateData(upgrade: viewModel.upgrade) else { return emptyView }
        
        guard let charge_active = upgradeState.charge_active else { return emptyView }
        guard let charge_inactive = upgradeState.charge_inactive else { return emptyView }
        
        let charge_total = charge_active + charge_inactive
        
        let color = buildColor(charge_active: charge_active, charge_inactive: charge_inactive, charge_total: charge_total)
        
        return Capsule()
            .fill(color)
            .overlay(
                Text("\(charge_active) / \(charge_total)")
                    .foregroundColor(.black)
            ).eraseToAnyView()
    }
    
    var body: some View {
        HStack {
            Text("\(self.viewModel.upgrade.name)")
                .foregroundColor(.white)
                .font(.largeTitle)
                
            banner
                .frame(width: 50, height: 50, alignment: .top)
        }
        .padding(15)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            }
        )
        .onTapGesture {
            print("\(Date()) UpgradeView.Text.onTapGesture \(self.viewModel.imageUrl)")
            self.callback(self.viewModel)
        }
    }
}

struct UpgradeCardFlipView<Model: ShipViewModelProtocol> : View {
    @State var flipped = false
    let frontUrl: String
    let backUrl: String
    let viewModel: Model
    let update: (Bool) -> Void
    
    /// side: true (front), false (back)
    init(side: Bool,
         frontUrl: String,
         backUrl: String,
         viewModel: Model,
         update: @escaping (Bool) -> Void)
    {
        _flipped = State(initialValue: side)
        self.frontUrl = frontUrl
        self.backUrl = backUrl
        self.viewModel = viewModel
        self.update = update
    }
    
    var body: some View {
        ImageView(url: self.flipped ? self.frontUrl : self.backUrl,
                  moc: self.viewModel.moc,
              label: "upgrade")
            .rotation3DEffect(self.flipped ? Angle(degrees: 360): Angle(degrees:
                0),
                              axis: (x: CGFloat(0), y: CGFloat(1), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                self.flipped.toggle()
                self.update(self.flipped)
            }
            .frame(width: 500.0, height:350)
    }
}
