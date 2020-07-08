//
//  UpgradesView.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

// MARK:- Upgrades
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

struct UpgradeView: View {
    struct UpgradeViewModel {
        let upgrade: Upgrade
        
        var imageUrl: String {
            var imageUrl = ""
            
            let type = upgrade.sides[0].type.lowercased() + ".json"
            
            let jsonString = loadJSON(fileName: type, directoryPath: "upgrades")
            
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
            .background(Color.red)
//            .contentShape(RoundedRectangle(cornerRadius: 10))
//            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                print("\(Date()) UpgradeView.Text.onTapGesture \(self.viewModel.imageUrl)")
                self.showImageOverlay = true
                self.shipViewModel.displayImageOverlay = true
                self.imageOverlayUrl = self.viewModel.imageUrl
            }
    }
}


struct UpgradeSummary : Identifiable {
    let id = UUID()
    let type: String
    let name: String
    let prettyName: String
}

enum UpgradeCardEnum : CaseIterable {
    static var allCases: [UpgradeCardEnum] {
        return [.astromech(""),
        .cannon(""),
        .cargo(""),
        .command(""),
        .configuration(""),
        .crew(""),
        .device(""),
        .forcepower(""),
        .gunner(""),
        .hardpoint(""),
        .illicit(""),
        .missile(""),
        .modification(""),
        .sensor(""),
        .tacticalrelay(""),
        .talent(""),
        .team(""),
        .tech(""),
        .title(""),
        .torpedo(""),
        .turret("")]
    }

    case astromech(String)
    case cannon(String)
    case cargo(String)
    case command(String)
    case configuration(String)
    case crew(String)
    case device(String)
    case forcepower(String)
    case gunner(String)
    case hardpoint(String)
    case illicit(String)
    case missile(String)
    case modification(String)
    case sensor(String)
    case tacticalrelay(String)
    case talent(String)
    case team(String)
    case tech(String)
    case title(String)
    case torpedo(String)
    case turret(String)
}


