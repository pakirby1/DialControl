//
//  FeaturesManager.swift
//  Done
//
//  Created by Phil Kirby on 11/24/18.
//  Copyright © 2018 SoftDesk. All rights reserved.
//

import Foundation

class FeaturesManager {
    var features: [String: Feature] = [:]
    
    func add(_ feature: Feature) {
        features[feature.name] = feature
    }
    
    func remove(_ name: String) {
        features.removeValue(forKey: name)
    }
    
    func isFeatureEnabled(_ name: String) -> Bool {
        if let feature = features[name] {
            return feature.enabled
        }
        
        return false
    }
    
    private init() {
        configureFeatures()
    }
    
    static let shared = FeaturesManager()
    
    func configureFeatures() {
        // features
        add(DefaultFeature(name: "DialTest", enabled: true))
        add(DefaultFeature(name: "PilotStateData_Change", enabled: true))
        add(DefaultFeature(name: "UpdateImageUrls", enabled: true))
        add(DefaultFeature(name: "Redux", enabled: false))
        add(DefaultFeature(name: "MyRedux", enabled: true))
        add(DefaultFeature(name: "Redux_ShipView", enabled: false))
    }
}

protocol Feature {
    var name: String { get }
    var enabled: Bool { get }
}

struct DefaultFeature: Feature {
    let name: String
    let enabled: Bool
}
