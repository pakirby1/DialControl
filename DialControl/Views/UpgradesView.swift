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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades) {
                    UpgradeView(viewModel: UpgradeView.UpgradeViewModel(upgrade: $0),
                                showImageOverlay: self.$showImageOverlay,
                                imageOverlayUrl: self.$imageOverlayUrl)
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
    }
    
    let viewModel: UpgradeViewModel
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
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
            }
    }
}

struct UpgradeCardFlipView : View {
    struct CardFlipViewModel {
        let sidesUrls: [String] = ["Card_Upgrade_108",
             "Card_Upgrade_108b"]
        
        var front: UIImage {
            let image = UIImage(named: sidesUrls[0])
            return image!
        }
        
        var back: UIImage {
            return UIImage(named: sidesUrls[1])!
        }
    }
    
    @State var flipped = false
    let viewModel = CardFlipViewModel()
    
    var body: some View {
        Image(uiImage: self.flipped ? viewModel.back : viewModel.front)
            .rotation3DEffect(self.flipped ? Angle(degrees: 360): Angle(degrees:
                0),
                              axis: (x: CGFloat(0), y: CGFloat(1), z: CGFloat(0)))
            .animation(.default) // implicitly applying animation
            .onTapGesture {
                self.flipped.toggle()
            }
    }
}
