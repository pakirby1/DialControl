//
//  JSONSerialization.swift
//  DialControl
//
//  Created by Phil Kirby on 7/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation

protocol JSONSerialization {
    static func deserialize<T: Decodable>(jsonString: String) -> T
    static func serialize<T: Encodable>(type: T) -> String
}

extension JSONSerialization {
    static func deserialize<T: Decodable>(jsonString: String) -> T {
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        guard let ret = try? decoder.decode(T.self, from: jsonData) else {
            fatalError("Failed to decode from bundle \(jsonString).")
        }

        return ret
    }
    
    static func serialize<T: Encodable>(type: T) -> String {
        let encoder = JSONEncoder()
        
        // open func encode<T>(_ value: T) throws -> Data where T : Encodable
        guard let data = try? encoder.encode(type) else {
            fatalError("Failed to encode.")
        }

        let str = String(decoding: data, as: UTF8.self)
        
        return str
    }
}

