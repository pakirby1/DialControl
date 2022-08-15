//
//  ViewModelRepresentable.swift
//  DialControl
//
//  Created by Phil Kirby on 8/15/22.
//  Copyright © 2022 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol ViewModelRepresentable: View {
    associatedtype Store: ObservableObject
    associatedtype ViewModel
    associatedtype V : SwiftUI.View
    func buildViewModel(store: Store) -> ViewModel
    func body(viewModel: ViewModel) -> V
}

/*
 func render(state: State, dispatch: @escaping DispatchFunction) -> V {
     let props = map(state: state, dispatch: dispatch)
     return body(props: props)
 }

 var body: StoreConnector<State, V> {
     return StoreConnector(content: render)
 }
 */
extension ViewModelRepresentable {
    func render(store: Store) -> V {
        let viewModel = buildViewModel(store: store)
        return body(viewModel: viewModel)
    }
    
    var body: StoreDataProvider<Store, V> {
        return StoreDataProvider(content: render(store:))
    }
}

/*
 public struct StoreConnector<State: FluxState, V: View>: View {
     @EnvironmentObject var store: Store<State>
     let content: (State, @escaping (Action) -> Void) -> V
     
     public var body: V {
         content(store.state, store.dispatch(action:))
     }
 }

 */
struct StoreDataProvider<Store: ObservableObject, V: View> : View {
    @EnvironmentObject var store: Store
    let content: (Store) -> V
        
    public var body: V {
        self.content(self.store)
    }
}
