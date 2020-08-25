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
    var BORDER_ACTIVE: Color { get }
    var BORDER_INACTIVE: Color { get }
    var TEXT_FOREGROUND: Color { get }
    var BACKGROUND: Color { get }
}

struct LightTheme : Theme {
    let BACKGROUND: Color = Color.white
    let BUTTONBACKGROUND: Color = Color(red: 255/255, green: 225/255, blue: 139/255)
    let BORDER_ACTIVE: Color = Color(red:112/255, green: 223/255, blue: 253)
    let BORDER_INACTIVE: Color = Color(red:102/255, green: 105/255, blue: 111/255)
    let TEXT_FOREGROUND: Color = Color.black
}

struct WestworldUITheme : Theme {
    let BUTTONBACKGROUND: Color = Color(red: 55/255, green: 59/255, blue: 64/255)
    let BACKGROUND: Color = Color(red: 57/255, green: 60/255, blue: 67/255)
    let BORDER_ACTIVE: Color = Color(red:112/255, green: 223/255, blue: 253)
    let BORDER_INACTIVE: Color = Color(red:102/255, green: 105/255, blue: 111/255)
    let TEXT_FOREGROUND: Color = Color.white
}

let regularMediumSymbolConfig = UIImage.SymbolConfiguration(pointSize: 48.0,
                                                            weight: .regular,
                                                            scale: .medium)
