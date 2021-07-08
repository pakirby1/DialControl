//
//  ImageService.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TimelaneCombine

class ImageService : ObservableObject, UrlBuildable {
    @Published var currentImage: DownloadImageEvent?
    private var cancellables = Set<AnyCancellable>()
    
    private var isCancelled: Bool = false
    
    private var cancelPublisher = CurrentValueSubject<Bool, Never>(false)
    
    func downloadImage(at: URL) -> AnyPublisher<UIImage, URLError> {
        return URLSession.shared.dataTaskPublisher(for: at)
                .compactMap { UIImage(data: $0.data) }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
    }
    
    func cancel() {
        currentImage = nil
        cancellables.removeAll()
        self.cancelPublisher.send(true)
        print("\(#function) isCancelled: \(isCancelled)")
    }
    
    typealias DownloadImageEventResult = Result<DownloadImageEvent, URLError>
    typealias DownloadImageEventResultPublisher = AnyPublisher<DownloadImageEventResult, Never>
    
    func pak_downloadAllImage() -> DownloadImageEventResultPublisher {
        let urls = buildImagesUrls().compactMap{ URL(string: $0) }
        let pub: AnyPublisher<URL, Never> = urls.publisher.eraseToAnyPublisher()
        var index: Int = 0
        let delay: Int = 2
        
        let downloadResults = pub.flatMap(maxPublishers: .max(1)) { url -> DownloadImageEventResultPublisher in
            print("\(#function) \(url)")
            index += 1
            
            // download & create event
            return self.downloadImage(at: url)
                    .print()
                    .map{ _ in DownloadImageEvent(
                            index: index,
                            total: urls.count,
                            url: url.absoluteString,
                            isCompleted: false) }
                    .delay(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(delay)),
                           scheduler: RunLoop.main)
                    .convertToResult()
                    .eraseToAnyPublisher()
        }
        .append(Just(DownloadImageEvent.buildCompleted()))
        .eraseToAnyPublisher()
        
        return self.cancelPublisher
                        .print("Print example")
                        .filter{ $0 == false}
                        .flatMap{ _ in
                            downloadResults
                        }
            .lane("ReduxViewModel.init() self.store.$state")
            .eraseToAnyPublisher()
    }
    
    func downloadAllImages() ->  DownloadImageEventResultPublisher {
        let urls = buildImagesUrls().compactMap{ URL(string: $0) }
        let pub: AnyPublisher<URL, Never> = urls.publisher.eraseToAnyPublisher()
        var index: Int = 0
        let delay: Int = 2
        
                
        let first = pub.flatMap(maxPublishers: .max(1)) { url -> DownloadImageEventResultPublisher in
            print("\(#function) \(url)")
            index += 1
            
            // download & create event
            return self.downloadImage(at: url)
                    .print()
                    .map{ _ in DownloadImageEvent(
                            index: index,
                            total: urls.count,
                            url: url.absoluteString,
                            isCompleted: false) }
                    .delay(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(delay)),
                           scheduler: RunLoop.main)
                    .convertToResult()
                    .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
        
        let second = Just(DownloadImageEvent.buildCompleted())
        
        return second
            .print("prepend")
            .prepend(first)
            .eraseToAnyPublisher()
    }
}

protocol UrlBuildable {
    func buildImagesUrls() -> [String]
}

extension UrlBuildable {
    func buildImagesUrls() -> [String] {
        var ret: [String] = []
        
        ret.append("https://pakirby1.github.io/images/XWing/upgrades/perceptivecopilot.png")
        ret.append("https://pakirby1.github.io/images/XWing/upgrades/landocalrissian.png")
        ret.append("https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png")
        ret.append("https://pakirby1.github.io/images/XWing/upgrades/chewbacca-crew-swz19.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/r7a7.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/moldycrow.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/fanatical.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/4lom.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/drk1probedroids.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/delayedfuses.png")

        return ret
    }
    
    func buildImagesUrls() -> [URL] {
        return buildImagesUrls().compactMap({ URL(string: $0) })
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
    
    static func buildCompleted() -> ImageService.DownloadImageEventResult {
        return .success(DownloadImageEvent(index: 0, total: 0, url: "", isCompleted: true))
    }
}

// https://www.swiftbysundell.com/articles/handling-loading-states-in-swiftui/
enum LoadingState<Value> {
    case idle
    case loading
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

struct AsyncContentView<Source: LoadableObject,
                        LoadingView: View,
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
    }

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading:
            loadingView
        case .failed(let error):
            EmptyView()
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
        state = .loading

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
