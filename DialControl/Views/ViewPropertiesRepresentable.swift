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

/// Can't we just make a version that would directly connect the view with the store in a simpe way?
/*
 
 
public protocol ConnectedView: View {
    associatedtype State: FluxState
    associatedtype Props
    associatedtype V: View
    
    func map(state: State, dispatch: @escaping DispatchFunction) -> Props
    func body(props: Props) -> V
}

public extension ConnectedView {
    func render(state: State, dispatch: @escaping DispatchFunction) -> V {
        let props = map(state: state, dispatch: dispatch)
        return body(props: props)
    }
    
    var body: StoreConnector<State, V> {
        return StoreConnector(content: render)
    }
}
 */

protocol StoreConnected: View {
    associatedtype State
    associatedtype ViewProperties
    associatedtype V: View
    associatedtype Action
    
    func buildViewProperties(state: State) -> ViewProperties
    func body(properties: ViewProperties) -> V
}

extension StoreConnected {
    var body: StoreProvider<State, Action, V> {
        return StoreProvider(content: render)
    }
    
    func render(state: State, dispatch: @escaping (Action) -> Void) -> V {
        let props: ViewProperties = buildViewProperties(state: state)
        
        return body(properties: props)
    }
}

struct StoreProvider<State, Action, V:View>: View {
    @EnvironmentObject var store: Store<State, Action, MyEnvironment>
    
    let content: (State, @escaping (Action) -> Void) -> V
    
    var body: V {
        content(store.state, store.send)
    }
}

//public struct StoreConnector<State: FluxState, V: View>: View {
//    @EnvironmentObject var store: Store<State>
//    let content: (State, @escaping (Action) -> Void) -> V
//
//    public var body: V {
//        content(store.state, store.dispatch(action:))
//    }
//}

struct StoreConnectorTestView : StoreConnected {
    typealias ViewProperties = String
    typealias Action = MyAppAction
    
    func buildViewProperties(state: String) -> ViewProperties {
        ""
    }
    
    func body(properties: String) -> AnyView {
        Text("StoreConnectorTestView").eraseToAnyView()
    }
}
