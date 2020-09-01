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
    @EnvironmentObject var viewModel: ShipViewModel
    @State var imageName: String = ""
    let upgrades: [Upgrade]
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    @Binding var imageOverlayUrlBack: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades) {
                    UpgradeView(viewModel: UpgradeView.UpgradeViewModel(upgrade: $0),
                                showImageOverlay: self.$showImageOverlay,
                                imageOverlayUrl: self.$imageOverlayUrl,
                                imageOverlayUrlBack: self.$imageOverlayUrlBack)
//                        .environmentObject(self.viewModel)
                }
            }
        }
    }
}

// MARK:- UpgradeView
/*
 
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
                    imageUrl = sides[0].image
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
                        imageUrl = sides[1].image
                    }
                }
            }
            
            return imageUrl
        }
    }
    
    let viewModel: UpgradeViewModel
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    @Binding var imageOverlayUrlBack: String
    @EnvironmentObject var shipViewModel: ShipViewModel
    
    var body: some View {
        Text("\(self.viewModel.upgrade.name)")
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
            )
            .onTapGesture {
                print("\(Date()) UpgradeView.Text.onTapGesture \(self.viewModel.imageUrl)")
                self.showImageOverlay = true
                self.shipViewModel.displayImageOverlay = true
                self.imageOverlayUrl = self.viewModel.imageUrl
                self.imageOverlayUrlBack = self.viewModel.imageUrlBack
            }
    }
}

struct UpgradeCardFlipView : View {
    @State var flipped = false
    let frontUrl: String
    let backUrl: String
    let shipViewModel: ShipViewModel
    
    var body: some View {
        ImageView(url: self.flipped ? self.frontUrl : self.backUrl,
              shipViewModel: self.shipViewModel,
              label: "upgrade")
            .rotation3DEffect(self.flipped ? Angle(degrees: 360): Angle(degrees:
                0),
                              axis: (x: CGFloat(0), y: CGFloat(1), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                self.flipped.toggle()
            }
            .frame(width: 500.0, height:350)
            .environmentObject(self.shipViewModel)
    }
}
