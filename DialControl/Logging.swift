//
//  Logging.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

// MARK: - IPrintLog
protocol IPrintLog {
    var classFuncString: String { get set }
    func printLog(_ message: String)
}

extension IPrintLog {
    func printLog(_ message: String) {
        print("\(Date()) \(classFuncString) : \(message)")
    }
}
