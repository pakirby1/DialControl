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
        add(DefaultFeature(id: FeatureId.MyRedux, enabled: true))
        add(DefaultFeature(id: FeatureId.importXWS_HandleErrors, enabled: true))
        add(DefaultFeature(id: FeatureId.DownloadAllImages, enabled: true))
        add(DefaultFeature(id: FeatureId.FactionSquadList_DamagedPoints, enabled: true))
    }
}

enum FeatureId : String {
    case MyRedux
    case importXWS_HandleErrors
    case DownloadAllImages
    case FactionSquadList_DamagedPoints
}

protocol Feature {
    var id: FeatureId { get }
    var enabled: Bool { get }
}

struct DefaultFeature: Feature {
    let id: FeatureId
    let enabled: Bool
}
