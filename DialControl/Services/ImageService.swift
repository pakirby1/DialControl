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

// MARK:- Events
struct DownloadEvent: CustomStringConvertible {
    let index: Int
    let total: Int
    let url: String

    var completionRatio: CGFloat {
        return (CGFloat(index) / CGFloat(total))
    }

    var description: String {
        return "\(index) of \(total): \(file)"
    }

    var file: String {
        return url.components(separatedBy: "/").last ?? ""
    }
}

enum DownloadEventEnum : CustomStringConvertible {
    case idle
    case inProgress(DownloadEvent)
    case finished
    case failed(Error)
    case cancelled
    
    var description: String {
        switch(self) {
            case .inProgress(let die) :
                return "\(die.index) of \(die.total): \(die.file)"
            case .finished:
                return "Download Finished"
            case .failed(let error):
                return "Download Failed : \(error)"
            case .cancelled:
                return "Download Cancelled"
            case .idle:
                return "Tap to start download"
        }
    }
    
    func asResult() -> Result<DownloadEventEnum, Error> {
        return .success(self)
    }
}

enum DownloadImageError: Error {
    case notFound(String)
    case networkError
}

typealias DownloadImageEventEnumStream = AnyPublisher<Result<DownloadEventEnum, Error>, Never>

// MARK:- protocols
protocol ImageServiceProtocol : ObservableObject {
    var isCancelled: Bool { get set }
    func downloadAllImages() -> DownloadImageEventEnumStream
    func cancel()
}

extension ImageServiceProtocol {
    func downloadImage(at: URL) -> AnyPublisher<UIImage, URLError> {
        return URLSession.shared.dataTaskPublisher(for: at)
                .compactMap { UIImage(data: $0.data) }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
    }
}

class ImageService : ImageServiceProtocol, UrlBuildable {
    func cancel() {
        self.isCancelled = true
    }
    
    var isCancelled: Bool = false
    let finishedUrls: [String] = ["https://github.com/pakirby1/TableViewTutorial.git",
                              "https://github.com/pakirby1/asfasf.git",
                              "https://github.com/pakirby1/oieoiwer.git",
                          "https://github.com/AvdLee/CombineSwiftPlayground"]

    func downloadAllImages() -> DownloadImageEventEnumStream {
        func processImage(url: URL,
                          index: Int,
                          total: Int) -> DownloadImageEventEnumStream
        {
            return downloadImage(at: url)
                .print()
                .map{ image -> Result<DownloadEventEnum, Error> in
                    let die = DownloadEvent(index: index,
                                                 total: total,
                                                 url: url.absoluteString)
                    
                    return DownloadEventEnum.inProgress(die).asResult()
                }
                .catch{ [unowned self] error -> Just<Result<DownloadEventEnum, Error>> in
                    self.isCancelled = true
                    print("======= Failed =======")
                    return Just(.failure(error))
                }
                .delay(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(delay)),
                       scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        func buildReturn(append: Bool,
                         stream: DownloadImageEventEnumStream,
                         finished: DownloadImageEventEnumStream) -> DownloadImageEventEnumStream
        {
            if (append) {
                print("Appending Finished")
                return stream.append(finished).eraseToAnyPublisher()
            }
            
            return stream
        }
        
        
        var cancelledEvent: AnyPublisher<Result<DownloadEventEnum, Error>, Never> {
            let x = Just(DownloadEventEnum
                            .cancelled
                            .asResult()
            )
            
            return x.eraseToAnyPublisher()
        }
        
        let urls: [URL] = buildImagesUrls()
        let pub: AnyPublisher<URL, Never> = urls.publisher.eraseToAnyPublisher()
        var index: Int = 0
        let delay: Int = 2
        let total = urls.count
        
        let ret = pub.flatMap(maxPublishers: .max(1)) { url -> DownloadImageEventEnumStream in
            print("\(#function) \(url)")
            index += 1
            
            guard (!self.isCancelled) else {
                return cancelledEvent
            }

            guard (index < total) else {
                print("index >= total index: \(index) of \(total)")
                let finishedStream = DownloadEventEnum.finished
                
                let finished: DownloadImageEventEnumStream = Just(.success(finishedStream)).eraseToAnyPublisher()

                let downloadEvent = processImage(url: url,
                                                 index: index,
                                                 total: total)
                    .eraseToAnyPublisher()

                return buildReturn(append: !self.isCancelled, stream: downloadEvent, finished: finished)
            }

            // download & create event
            return processImage(url: url, index: index, total: total)
        }

        return ret.eraseToAnyPublisher()
    }
}

protocol UrlBuildable {
    func buildImagesUrls() -> [String]
}

extension UrlBuildable {
//    func buildImagesUrls() -> [String] {
//        var ret: [String] = []
//
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/perceptivecopilot.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/landocalrissian.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png")
//        ret.append("https://pakirby1.github.io/images/XWing/upgrades/chewbacca-crew-swz19.png")
//
//        return ret
//    }
    
    func buildImagesUrls() -> [URL] {
        return buildImagesUrls().compactMap({ URL(string: $0) })
    }
}

extension ImageService {
    private func getAllUpgradeFiles() -> [String] {
        var files: [String] = ["/upgrades/astromech.json",
                               "/upgrades/cannon.json"
        ]
        
        return files
    }
    
    private func getAllPilotFiles() -> [String] {
        var files: [String] = ["/pilots/scum-and-villainy/g-1a-starfighter.json",
                               "/pilots/first-order/tie-ba-interceptor.json"
        ]
        
        return files
    }
    
    private func getAllFiles() -> [String] {
        return getAllPilotFiles()
    }
    
    func buildImagesUrls() -> [String] {
        func buildPilotsStream() -> AnyPublisher<DownloadImageType<RemoteURL>, Never> {
            getAllPilotFiles()  // [String]
                .compactMap{ LocalURL(string:$0) }  // [LocalURL]
                .map{ DownloadImageType.pilot($0) } // [DownloadImageType<LocalURL>]
                .publisher  // Publishers.Sequence<[DownloadImageType<LocalURL>], Never>
                .map{ $0.buildXWS() } // Publishers.Sequence<[DownloadImageType<XWS>], Never>
                .compactMap{ $0.buildURL() } // Publishers.Sequence<[DownloadImageType<RemoteURL>], Never>
                .eraseToAnyPublisher()  // AnyPublisher<DownloadImageType<RemoteURL>, Never>
        }
        
        func buildUpgradesStream() -> AnyPublisher<DownloadImageType<RemoteURL>, Never> {
            getAllUpgradeFiles()  // [String]
                .compactMap{ LocalURL(string:$0) }  // [LocalURL]
                .map{ DownloadImageType.upgrade($0) } // [DownloadImageType<LocalURL>]
                .publisher  // Publishers.Sequence<[DownloadImageType<LocalURL>], Never>
                .map{ $0.buildXWS() } // Publishers.Sequence<[DownloadImageType<XWS>], Never>
                .compactMap{ $0.buildURL() } // Publishers.Sequence<[DownloadImageType<RemoteURL>], Never>
                .eraseToAnyPublisher()  // AnyPublisher<DownloadImageType<RemoteURL>, Never>
        }
        
        var ret: [String] = []
        var cancellables = Set<AnyCancellable>()
        
        buildPilotsStream()
            .merge(with: buildUpgradesStream())
            .sink(receiveValue: { remote in
                switch(remote) {
                    case .pilot(let url):
                        ret.append(url.absoluteString)
                    case .upgrade(let url):
                        ret.append(url.absoluteString)
                }
            }).store(in: &cancellables)

        return ret
    }
}

enum DownloadImageType<T> {
    case pilot(T)
    case upgrade(T)
}

typealias LocalURL = URL
typealias RemoteURL = URL
typealias XWS = String

extension DownloadImageType where T == LocalURL {
    func buildXWS() -> DownloadImageType<XWS> {
        switch(self) {
            case .pilot(let url):
                return .pilot("4lom")
            case .upgrade(let url):
                return .upgrade("4lom")
        }
    }
}

extension DownloadImageType where T == XWS {
    func buildURL() -> DownloadImageType<RemoteURL>? {
        switch(self) {
            case .pilot(let xws):
                if let remoteURL = URL(string: "https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png") {
                    return .pilot(remoteURL)
                }
                
            case .upgrade(let xws):
                if let remoteURL = URL(string: "https://pakirby1.github.io/images/XWing/upgrades/tantiveiv.png") {
                    return .upgrade(remoteURL)
                }
        }
        
        return nil
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
    
//    static func buildCompleted() -> ImageService.DownloadImageEventResult {
//        return .success(DownloadImageEvent(index: 0, total: 0, url: "", isCompleted: true))
//    }
}

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