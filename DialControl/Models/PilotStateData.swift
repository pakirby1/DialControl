//
//  PilotStateData.swift
//  DialControl
//
//  Created by Phil Kirby on 8/11/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation


struct UpgradeStateData {
    let force_active : Int?
    let force_inactive : Int?
    let charge_active : Int?
    let charge_inactive : Int?
    let selected_side : Int
}

struct PilotStateData {
    let adjusted_attack : Int
    let adjusted_defense : Int
    let hull_active : Int
    let hull_inactive : Int
    let shield_active : Int
    let shield_inactive : Int
    let force_active : Int
    let force_inactive : Int
    let charge_active : Int
    let charge_inactive : Int
    let selected_maneuver: String
    let shipID: String
    let upgradeStates : [UpgradeStateData]?
}
