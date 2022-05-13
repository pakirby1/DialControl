//
//  ViewPropertiesRepresentable.swift
//  AnimationTest
//
//  Created by Phil Kirby on 1/8/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

// class-only protocol since adopter must also adopt ObservableObject which
// requires a class
protocol ViewPropertyRepresentable: AnyObject {
    associatedtype ViewProperties
    associatedtype State
    associatedtype Store : StateRepresentable
    
    var store: Store { get }
    var cancellable: AnyCancellable? { get set }
    
    // Since this will be @Published
    // https://danielbernal.co/combine-and-protocols-in-swift/
    var viewProperties: ViewProperties { get set }
    
    var viewPropertiesPublished: Published<ViewProperties> { get }
    
    /// accessible via $viewProperties
    var viewPropertiesPublisher: Published<ViewProperties>.Publisher { get }
    
    func buildViewProperties(state: State) -> ViewProperties
    func configureViewProperties()
}

/// Store should adopt this protocol.
protocol StateRepresentable {
    associatedtype State
    var statePublisher: Published<State>.Publisher { get }
}

extension Store : StateRepresentable {
    var statePublisher: Published<State>.Publisher {
        self.$state
    }
}

