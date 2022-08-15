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
    func buildView(viewModel: ViewModel) -> V
}

extension ViewModelRepresentable {
    func render(store: Store) -> V {
        let viewModel = buildViewModel(store: store)
        return buildView(viewModel: viewModel)
    }
    
    var body: StoreDataProvider<Store, V> {
        return StoreDataProvider(content: render(store:))
    }
}

struct StoreDataProvider<Store: ObservableObject, V: View> : View {
    @EnvironmentObject var store: Store
    let content: (Store) -> V
        
    public var body: V {
        self.content(self.store)
    }
}
