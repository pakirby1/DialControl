//
//  Theme.swift
//  DialControl
//
//  Created by Phil Kirby on 3/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

protocol Theme {
    var BUTTONBACKGROUND: Color { get }
}

struct LightTheme : Theme {
    let BUTTONBACKGROUND: Color = Color(red: 255/255, green: 225/255, blue: 139/255)
}
