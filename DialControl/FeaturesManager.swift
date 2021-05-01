//
//  FeaturesManager.swift
//  Done
//
//  Created by Phil Kirby on 11/24/18.
//  Copyright © 2018 SoftDesk. All rights reserved.
//

import Foundation

class FeaturesManager {
    var features: [FeatureId: Feature] = [:]
    
    func add(_ feature: Feature) {
        features[feature.id] = feature
    }
    
    func remove(_ id: FeatureId) {
        features.removeValue(forKey: id)
    }
    
    func isFeatureEnabled(_ id: FeatureId) -> Bool {
        if let feature = features[id] {
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
        add(DefaultFeature(id: FeatureId.DialTest, enabled: true))
        add(DefaultFeature(id: FeatureId.PilotStateData_Change, enabled: true))
        add(DefaultFeature(id: FeatureId.UpdateImageUrls, enabled: true))
        add(DefaultFeature(id: FeatureId.Redux, enabled: false))
        add(DefaultFeature(id: FeatureId.MyRedux, enabled: true))
    }
}

enum FeatureId : String {
    case MyRedux
    case Redux
    case UpdateImageUrls
    case PilotStateData_Change
    case DialTest
}

protocol Feature {
    var id: FeatureId { get }
    var enabled: Bool { get }
}

struct DefaultFeature: Feature {
    let id: FeatureId
    let enabled: Bool
}
