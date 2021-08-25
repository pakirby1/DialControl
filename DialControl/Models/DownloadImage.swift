//
//  DownloadImage.swift
//  DialControl
//
//  Created by Phil Kirby on 8/25/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TimelaneCombine
import SwiftyJSON

// MARK:- Events
struct DownloadEvent: CustomStringConvertible {
    let index: Int
    let total: Int
    let url: String

    var completionRatio: CGFloat {
        return (CGFloat(index) / CGFloat(total))
    }

    var description: String {
        return "\(index) of \(total): \(file)"
    }

    var file: String {
        return url.components(separatedBy: "/").last ?? ""
    }
}

enum DownloadEventEnum : CustomStringConvertible {
    case idle
    case inProgress(DownloadEvent)
    case finished
    case failed(Error)
    case cancelled
    
    var description: String {
        switch(self) {
            case .inProgress(let die) :
                return "\(die.index) of \(die.total): \(die.file)"
            case .finished:
                return "Download Finished"
            case .failed(let error):
                return "Download Failed : \(error)"
            case .cancelled:
                return "Download Cancelled"
            case .idle:
                return "Tap to start download"
        }
    }
    
    func asResult() -> Result<DownloadEventEnum, Error> {
        return .success(self)
    }
}

enum DownloadImageError: Error {
    case notFound(String)
    case networkError
}

typealias DownloadImageEventEnumStream = AnyPublisher<Result<DownloadEventEnum, Error>, Never>

enum DownloadImageType<T> {
    case pilot(T)
    case upgrade(T)
}

typealias LocalURL = URL
typealias RemoteURL = URL
typealias XWS = String

/// https://pakirby1.github.io/images/XWing/pilots/majorvonreg.png
extension DownloadImageType where T == LocalURL {
    /// for pilot URL = "/pilots/first-order/tie-ba-interceptor.json"
    ///     ["majorvonreg", "holo", "ember", "firstorderprovocateur" ... ]
    /// for upgrade URL = "/upgrades/astromech.json
    ///     ["chopper", "genius", "r2astromech" ... ]
    func buildXWS() -> DownloadImageType<XWS> {
        switch(self) {
            case .pilot(let url):
                return .pilot("4lom")
            case .upgrade(let url):
                return .upgrade("4lom")
        }
    }
    
    func buildXWSs() -> [DownloadImageType<XWS>] {
        switch(self) {
            case .pilot(let url) :
                return getXWSForPilots(in: url)
            case .upgrade(let url) :
                return getXWSForUpgrades(in: url)
        }
    }
    
    func getXWSForPilots(in: URL) -> [DownloadImageType<XWS>] {
        return [
            .pilot("majorvonreg"),
            .pilot("holo"),
            .pilot("ember"),
            .pilot("firstorderprovocateur")
        ]
    }
    
    func getXWSForUpgrades(in: URL) -> [DownloadImageType<XWS>] {
        return [
            .upgrade("chopper"),
            .upgrade("genius"),
            .upgrade("r2astromech")
        ]
    }
}

extension DownloadImageType where T == XWS {
    static var pilotBaseURL = "https://pakirby1.github.io/images/XWing/pilots/"
    
    static var upgradeBaseURL = "https://pakirby1.github.io/images/XWing/upgrades/"
    
    func buildURL() -> DownloadImageType<RemoteURL>? {
        
        switch(self) {
            case .pilot(let xws):
                if let remoteURL = URL(string: "https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png") {
                    return .pilot(remoteURL)
                }
                
            case .upgrade(let xws):
                if let remoteURL = URL(string: "https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png") {
                    return .upgrade(remoteURL)
                }
        }
        
        return nil
    }
    
    func buildURL_New() -> DownloadImageType<RemoteURL>? {
        switch(self) {
            case .pilot(let xws):
                if let url = URL(string: "\(DownloadImageType<XWS>.pilotBaseURL)\(xws).png") {
                    return .pilot(url)
                }
            case .upgrade(let xws):
                if let url = URL(string: "\(DownloadImageType<XWS>.upgradeBaseURL)\(xws).png") {
                    return .upgrade(url)
                }
        }
        
        return nil
    }
}

enum DownloadImageEventState {
    case idle
    case inProgress(DownloadImageEvent)
    case completed
    case failed(String)
}

struct DownloadImageEvent: CustomStringConvertible {
    let index: Int
    let total: Int
    let url: String
    let isCompleted: Bool
    
    var completionRatio: CGFloat {
        return (CGFloat(index) / CGFloat(total))
    }
    
    var description: String {
        return "\(index) of \(total): \(file)"
    }
    
    var file: String {
        return url.components(separatedBy: "/").last ?? ""
    }
    
//    static func buildCompleted() -> ImageService.DownloadImageEventResult {
//        return .success(DownloadImageEvent(index: 0, total: 0, url: "", isCompleted: true))
//    }
}
