//
//  JSONSerialization.swift
//  DialControl
//
//  Created by Phil Kirby on 7/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

protocol JSONSerialization {
    static func serialize<T: Decodable>(jsonString: String) -> T
}

extension JSONSerialization {
    static func serialize<T: Decodable>(jsonString: String) -> T {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        guard let ret = try? decoder.decode(T.self, from: jsonData) else {
            fatalError("Failed to decode from bundle \(jsonString).")
        }

        return ret
    }
}

