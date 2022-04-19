//
//  FeaturesManager.swift
//  Done
//
//  Created by Phil Kirby on 11/24/18.
//  Copyright © 2018 SoftDesk. All rights reserved.
//

import Foundation

/*
 fm.isFeatureEnabled(FeatureId.getShips) { isTrue in
    if (isTrue) {
        // foo()
    } else {
        // bar()
    }
 }
 
 fm.isFeatureEnabled(FeatrueId.getShips, enabled: {}, disabled: {})
 
 func isFeatureEnabled(_ id: FeatureId
 */
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
        add(Feature(id: FeatureId.MyRedux, enabled: true))
        add(Feature(id: FeatureId.getShips, enabled: true))
    }
}

extension FeaturesManager {
    func isFeatureEnabled<T>(_ id: FeatureId, completion: (Bool) -> T) -> T {
        let status = isFeatureEnabled(id)
        return completion(status)
    }
}

extension FeaturesManager {
    func isFeatureEnabled(_ id: FeatureId, enabled: () -> (), disabled: () -> ()) {
        let status = isFeatureEnabled(id)
        
        if status {
            enabled()
        } else {
            disabled()
        }
    }
}

enum FeatureId : String {
    case MyRedux
    case getShips
}

protocol IFeature {
    var id: FeatureId { get }
    var enabled: Bool { get }
}

struct Feature: IFeature {
    let id: FeatureId
    let enabled: Bool
}
