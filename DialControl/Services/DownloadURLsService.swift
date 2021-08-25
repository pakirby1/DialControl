//
//  DownloadURLsService.swift
//  DialControl
//
//  Created by Phil Kirby on 8/25/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

enum DownloadURLsError: Swift.Error {
    case fileNotFound(name: String)
    case fileDecodingFailed(name: String, Swift.Error)
}

protocol DownloadURLsProtocol {
    var pilotsBaseURL: String { get }
    func buildFileURLs() -> [URL]
    func buildXWS(file: URL) throws -> [String]
    func buildURLs(xwsArr: [String]) -> [URL]
}

extension DownloadURLsProtocol {
    var pilotsBaseURL: String {
        return "https://pakirby1.github.io/images/XWing/pilots/"
    }
    
    var upgradesBaseURL: String {
        return "https://pakirby1.github.io/images/XWing/upgrades/"
    }
}

struct DownloadURLsService : DownloadURLsProtocol {
    /// returns
    ///     ["first-order/tie-fo-fighter.json",
    ///     "galactic-empire/tie-rb-heavy.json"]
    private func readRecursive(subDirectory: String) -> [String] {
        guard let directoryURL = URL(string: subDirectory, relativeTo: Bundle.main.bundleURL) else {
            return []
        }
        
        var ret: [String] = []
        
        print(directoryURL.path)
        
        if let enumerator =
            FileManager.default.enumerator(atPath: directoryURL.path)
        {
            for case let path as String in enumerator {
                // Skip entries with '_' prefix, for example
                if path.hasSuffix("json") {
                    ret.append(path)
                }
            }
        }
        
        return ret
    }
    
    func buildFileURLs() -> [URL] {
        // get all files in Bundle/Data/Pilots and sub directories
        let files = readRecursive(subDirectory: "pilots")
        let urls: [URL] = files.map{ URL(string: $0)! }
        
        return urls
    }
    
    func buildXWS(file: URL) throws -> [String] {
        // get the xws for each pilot from JSON file
        guard let directoryURL = URL(string: "pilots", relativeTo: Bundle.main.bundleURL) else {
            return []
        }
        
        let path = directoryURL.appendingPathComponent(file.absoluteString)
        
        do {
            let data = try Data(contentsOf: path)
            let json = try JSON(data: data)
            
            let pilotsXWSArr = json["pilots"].arrayValue.map { $0["xws"].stringValue }
            
            return pilotsXWSArr
        } catch {
            throw DownloadURLsError.fileDecodingFailed(name: path.absoluteString, error)
        }
        
        return []
    }
    
    func buildURLs(xwsArr: [String]) -> [URL] {
        // are we building a pilot or upgrade URL?
        return xwsArr.compactMap{ xws -> URL? in
            let url = "\(pilotsBaseURL)\(xws).png"
            return URL(string: url)
        }
    }
}
