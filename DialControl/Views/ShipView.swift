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

struct ShipView: View {
    let squadPilot: SquadPilot
    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    @State var showCardOverlay: Bool = false
    
    let dial: [String] = [
                  "1TW",
                  "1YW",
                  "2TB",
                  "2BB",
                  "2FB",
                  "2NB",
                  "2YB",
                  "3LR",
                  "3TW",
                  "3BW",
                  "3FB",
                  "3NW",
                  "3YW",
                  "3PR",
                  "4FB",
                  "4KR",
                  "5FW"
                ]
    
    var backButtonView: some View {
        Button(action: {
            self.viewFactory.viewType = .squadView
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Back to Squad")
            }
        }.padding(5)
    }
    
    var clearView: some View {
        Color
            .clear
            .border(Color.red, width: 5)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                backButtonView
                    .border(Color.blue, width: 2)
            }
            .frame(width: 150, height: 50, alignment: .leading)
            .border(Color.blue, width: 2)
            
            PilotDetailsView(pilot: squadPilot, displayUpgrades: true, displayHeaders: false)
                .padding(2)
                .border(Color.green, width: 2)
            
            HStack(alignment: .center) {
//                clearView
                Image(uiImage: getShipImage(shipName: squadPilot.ship))
                    .resizable()
                    .aspectRatio(UIImage(named: "Card_Pilot_103")!.size, contentMode: .fit)
                    .frame(width: 350.0,height:500)
                    .border(Color.green, width: 2)
                    .onTapGesture { self.showCardOverlay.toggle() }
                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                
                VStack(spacing: 20) {
                    LinkedView(maxCount: 8, type: StatButtonType.force)
                    LinkedView(maxCount: 10, type: StatButtonType.charge)
                    LinkedView(maxCount: 32, type: StatButtonType.shield)
                }.border(Color.green, width: 2)

                DialView(temperature: 0, diameter: 400, currentManeuver: $currentManeuver, dial: dial, displayAngleRanges: false)
                    .frame(width: 400.0,height:400).border(Color.green, width: 2)
            }
            
            UpgradesView(upgrades: squadPilot.upgrades.modifications + squadPilot.upgrades.sensors + squadPilot.upgrades.talents)
            
        }.border(Color.red, width: 2)
    }
    
    //    "tieskstriker"
    func getShipImage(shipName: String) -> UIImage {
        let shipJSON: String = ""
        
        let stringPath = Bundle.main.path(forResource: "tie-sk-striker",
                                          ofType: "json",
                                          inDirectory: "pilots/galactic-empire")
        
        if let shipJSONUrl = shipLookupTable[shipName] {
            if let path = Bundle.main.path(forResource: shipJSONUrl, ofType: "json")
            {
                print("shipJSONUrl: \(path)")
            }
        }
        
//        let imageName = "" // your image name here
//        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
//        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        
        return UIImage(contentsOfFile: "Card_Pilot_103")!
    }
    
    var shipLookupTable: [String:String] = [
        "alphaclassstarwing" : "pilots/galactic-empire/alpha-class-star-wing",
        "tieskstriker" : "pilots/galactic-empire/tie-sk-striker",
        "tieadvancedx1" : "pilots/galactic-empire/tie-advanced-x1"
    ]
}

struct UpgradesView: View {
    let upgrades: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades, id:\.self) {
                    Text("\($0)")
                        .foregroundColor(.white)
                        .font(.largeTitle)
//                        .frame(width: 200, height: 200)
                        .padding(15)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

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
