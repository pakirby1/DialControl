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

struct UpgradeTextView: View {
    let utility = UpgradeTextUtility()
    @State var text = "UpgradeTextView"
    
    var body: some View {
        let substrings = utility.testMergeTypes()
        utility.buildViews(substrings)
    }
}

class UpgradeTextUtility {
    enum SubstringType : Equatable, CustomStringConvertible {
        var description: String {
            switch(self) {
                case .text(let val):
                    return val
                case .symbol(let val):
                    return val
            }
        }
        
        case text(String)
        case symbol(String)
        
        func merge(_ type: Self) -> SubstringType? {
            if self == type {
                switch (self, type) {
                    case (.text(let lhs), .text(let rhs)):
                        return .text(lhs + rhs)
                    case (.symbol(let lhs), .symbol(let rhs)):
                        return .symbol(lhs + rhs)
                    default:
                        return nil
                }
            }
            
            return nil
        }
        
//        func hasSameCaseAs(_ type: Self) -> Bool {
//            switch self {
//                case .text: if case .text = type { return true }
//                case .symbol: if case .symbol = type { return true }
//            }
//            return false
//        }
//
        public static func ==(lhs: SubstringType, rhs:SubstringType) -> Bool {
                switch (lhs,rhs) {
                    case (.text, .text):
                        return true
                    case (.symbol, .symbol):
                        return true
                default:
                    return false
                }
        }
    }
    
    /*
     Given a string of length n, return an array that contains all subsets
     separated by either '[' or ']' characters.
     
     if the input is:
     "After you perform a [Straight] maneuver, you may perform a [Boost] action."
                                   i
                          s        e
     
     0  "After you perform a "
     1  "[Straight]"
     2  " maneuver, you may perform a "
     3  "[Boost]"
     4  " action."
     */
    func findDelimitedSubstrings(_ input : String) -> [String] {
        func updateResult(input: String, result: inout [String]) {
            if (!input.isEmpty) {
                result.append(input)
            }
        }
        
        if (input.isEmpty) { return [] }
        var i = 0
        var start = 0
        var ret = [String]()
        let len = input.count
        
        while i < len {
            let currentIndex = input.index(input.startIndex, offsetBy: i)
            let startIndex = input.index(input.startIndex, offsetBy: start)
            
            if (input[currentIndex] == "[") {
                let endIndex = input.index(before: currentIndex)
                let sub = String(input[startIndex...endIndex])
                updateResult(input: sub, result: &ret)
                
                start = i
            } else if (input[currentIndex] == "]") {
                let endIndex = currentIndex
                let sub = String(input[startIndex...endIndex])
                updateResult(input: sub, result: &ret)
                
                start = i + 1
            }
            
            i += 1
        }
        
        if (start < len) {
            let startIndex = input.index(input.startIndex, offsetBy: start)
            let endIndex = input.index(input.startIndex, offsetBy: len)
            let sub = String(input[startIndex..<endIndex])
            
            updateResult(input: sub, result: &ret)
        }
        
        return ret
    }
    
    /*
     "After you fully execute a ",
     "[3 ",
     "[Straight]",
     "]",
     " or ",
     "[4 ",
     "[Straight]",
     "]",
     " maneuver, you may perform a boost using the ",
     "[1 ",
     "[Straight]",
     "]",
     " template. (This is not an action)."
     
    Should convert to
     [
        SubstringType.text("After you fully execute a "),
        SubstringType.text("[3 "),
        SubstringType.symbol("[Straight]")
        ...
     ]
     */
    func createSubstringArray(_ input: [String]) -> [SubstringType] {
        var ret = [SubstringType]()
        
        for str in input {
            let startIndex = str.startIndex
            let endIndex = str.index(before: str.endIndex)
            
            if (str[startIndex] == "[") && (str[endIndex] == "]") {
                ret.append(.symbol(str))
            } else {
                ret.append(.text(str))
            }
        }
        
        return ret
    }
    
    /*
     merge same contiguous substring types
     
     "After you fully execute a ",
     "[3 ",
     "[Straight]",
          
    Should convert to
     [
        SubstringType.text("After you fully execute a [3 "),
        SubstringType.symbol("[Straight]")
        ...
     ]

     */
    func mergeSameSubstringTypes(_ input: [SubstringType]) -> [SubstringType] {
        var results = [SubstringType]()
        var mergedSubtype: SubstringType?
        let len = input.count
        var i = 0
        
        if len == 0 { return [] }
        
        while i < len {
            let first = input[i]
            
            if let current = mergedSubtype {
                if let merged = current.merge(first) {
                    mergedSubtype = merged
                } else {
                    results.append(current)
                    mergedSubtype = first
                }
            } else {
                mergedSubtype = first
            }
            
            i += 1
        }
        
        // If we have a mergedSubtype, add it to the results
        if (i == len) {
            if let current = mergedSubtype {
                results.append(current)
            }
        }
        
            return results
    }
    
    private func getSymbol(_ input: String) -> String {
        //strip off the brackets
        
        switch(input) {
            case "[Straight]":
                return "8"
            case "[Focus]":
                return "f"
            case "[Evade]":
                return "e"
            case "[Lock]":
                return "l"
            case "[Boost]":
                return "b"
            case "[Calculate]":
                return "a"
            case "[Hit]":
                return "d"
            case "[Critical Hit]":
                return "c"
            case "[Charge]":
                return "g"
            case "[Force]":
                return "h"
            case "[Reinforce]":
                return "i"
            case "[Jam]":
                return "j"
            case "[Cloak]":
                return "k"
            case "[Coordinate]":
                return "o"
            case "[Reload]":
                return "="
            case "[Rotate Arc]":
                return "R"
            case "[Front Arc]":
                return "{"
            case "[Rear Arc]":
                return "|"
            case "[Bullseye Arc]":
                return "}"
            case "[Right Arc]":
                return "¢"
            case "[Left Arc]":
                return "£"
            case "[Full Front Arc]":
                return "~"
            case "[Full Rear Arc]":
                return "¡";
            case "[Left Sloop]":
                return "1"
            case "[Right Sloop]":
                return "3"
            case "[Koigran Turn]":
                return "2"
            case "[Left Turn]":
                return "4"
            case "[Right Turn]":
                return "6"
            case "[Bank Left]":
                return "7"
            case "[Bank Right]":
                return "9"
            case "[Left Talon]":
                return ":"
            case "[Right Talon]":
                return ";"
            case "[Barrel Roll]":
                return "r"
            case "[Slam]":
                return "s"
            default:
                return ""
        }
    }
    
    func buildViews(_ input: [SubstringType]) -> some View {
        func buildView(_ type: SubstringType) -> Text {
            switch(type) {
                case .text(let val):
                    return Text(val)
                case .symbol(let val):
                    return Text(getSymbol(val))
                        .font(.custom("xwing-miniatures", size: 18))
            }
        }
        
        return VStack(alignment: .center) {
            input.reduce(Text(""), { $0 + buildView($1) } )
        }
    }
    
    //MARK: - Tests
    func testEmptyInput() -> [String] {
        return findDelimitedSubstrings("")
    }
    
    func testSimpleInput() -> [String] {
        let input = "After you perform a [Straight] maneuver, you may perform a [Boost] action."
        return findDelimitedSubstrings(input)
    }
    
    func testComplexInput() -> [String] {
        let input =  "After you fully execute a [3 [Straight]] or [4 [Straight]] maneuver, you may perform a boost using the [1 [Straight]] template. (This is not an action)."
        
        return findDelimitedSubstrings(input)
    }
    
    func testCreateSubstringArray() -> [SubstringType] {
        let input =  "After you fully execute a [3 [Straight]] or [4 [Straight]] maneuver, you may perform a boost using the [1 [Straight]] template. (This is not an action)."
        
        let substrings = findDelimitedSubstrings(input)
        return createSubstringArray(substrings)
    }
    
    /*
     let substrings = utility.testMergeTypes()
     utility.buildViews(substrings) // Builds a single Text view from the substrings
     */
    func testMergeTypes() -> [SubstringType] {
//        let input =  "After you fully execute a [3 [Straight]] or [4 [Straight]] maneuver, you may perform a boost using the [1 [Straight]] template. (This is not an action)."
        
//        let input = "While you perform a primary attack, if you are damaged, you may change 1 [Focus] result to a [Hit] result."
        
        let input = "While you perform an attack, if the defender is in your [Bullseye Arc], you may change 1 [Hit] result to a [Critical Hit] result."
        
        let substrings = findDelimitedSubstrings(input)
        let substringTypes = createSubstringArray(substrings)
        return mergeSameSubstringTypes(substringTypes)
    }
    
    
}
