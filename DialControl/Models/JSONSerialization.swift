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

enum JSONSerializationError : LocalizedError {
    case dataCorrupted
    case keyNotFound(String)
    case valueNotFound(String)
    case typeMismatch(String)
    
    var errorDescription: String? {
        switch(self) {
            case .dataCorrupted :
                return "XWS Data is invalid."
            case .keyNotFound(let key):
                return "Key Not Found: \(key)"
            case .valueNotFound(let value):
                return "Value Not Found: \(value)"
            case .typeMismatch(let type):
                return "Type Mismatch: \(type)"
        }
    }
}

extension JSONSerialization {
    /// JSON -> T
    static func deserialize<T: Decodable>(jsonString: String) -> T {
        print(jsonString)
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        var ret: T? = nil   // FIXME: How do I NOT use optionals???
        
//        guard let ret = try? decoder.decode(T.self, from: jsonData) else {
//            fatalError("Failed to decode from bundle \(jsonString).")
//        }
        
        do {
            ret = try decoder.decode(T.self, from: jsonData)
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
    
        return ret! // FIXME: How do I NOT use optionals???
    }
    
    static func deserialize_throws<T: Decodable>(jsonString: String) throws -> T {
        print(jsonString)
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(T.self, from: jsonData)
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
            throw JSONSerializationError.dataCorrupted
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            throw JSONSerializationError.keyNotFound("\(key) \(context.codingPath)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            throw JSONSerializationError.valueNotFound("\(value) \(context.codingPath)")
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
            throw JSONSerializationError.typeMismatch("\(type) \(context.codingPath)")
        } catch {
            print("error: ", error)
            throw error
        }
    }
    
    /// T -> JSON
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

