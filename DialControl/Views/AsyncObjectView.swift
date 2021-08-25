//
//  AsyncObjectView.swift
//  DialControl
//
//  Created by Phil Kirby on 8/25/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// https://www.swiftbysundell.com/articles/handling-loading-states-in-swiftui/
enum LoadingState<Value> {
    case idle
    case loading(Double)
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

protocol LoadableView: View {
    var ratio: Double { get set }
}

struct SimpleLoadingView: LoadableView {
    @State var ratio: Double
    
    var body: some View {
        Text("SimpleLoadingView ratio: \(ratio)")
    }
}

struct AsyncContentView<Source: LoadableObject,
                        LoadingView: LoadableView,
                        Content: View>: View {
    @ObservedObject var source: Source
    var loadingView: LoadingView
    var content: (Source.Output) -> Content

    init(source: Source,
         loadingView: LoadingView,
         @ViewBuilder content: @escaping (Source.Output) -> Content) {
        self.source = source
        self.loadingView = loadingView
        self.content = content
        
//        self.loadingView.
    }

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading(let ratio):
            loadingView
//                .overlay(Text("ratio: \(ratio)"))
        case .failed(let error):
            loadingView
                .overlay(Text("error: \(error.localizedDescription)"))
        case .loaded(let output):
            content(output)
        }
    }
}

class PublishedObject<Wrapped: Publisher>: LoadableObject {
    @Published private(set) var state = LoadingState<Wrapped.Output>.idle

    private let publisher: Wrapped
    private var cancellable: AnyCancellable?

    init(publisher: Wrapped) {
        self.publisher = publisher
    }

    func load() {
        state = .loading(0)

        cancellable = publisher
            .map(LoadingState.loaded)
            .catch { error in
                Just(LoadingState.failed(error))
            }
            .sink { [weak self] state in
                self?.state = state
            }
    }
}

/*
extension AsyncContentView {
    init<P: Publisher>(
        source: P,
        @ViewBuilder content: @escaping (P.Output) -> Content
    ) where Source == PublishedObject<P> {
        self.init(
            source: PublishedObject(publisher: source),
            content: content
        )
    }
}
*/
