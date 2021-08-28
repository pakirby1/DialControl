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
import SwiftyJSON
import CoreData

// MARK:- protocol
protocol ImageServiceProtocol : ObservableObject {
    var isCancelled: Bool { get set }
    func downloadAllImages() -> DownloadImageEventEnumStream
    func cancel()
}

extension ImageServiceProtocol {
    func cancel() {
        self.isCancelled = true
    }
}

// MARK:- service
class ImageService : ImageServiceProtocol {
    var urls: [String] = []
    var isCancelled: Bool = false
    let service: INetworkCacheService
    
    init(moc: NSManagedObjectContext) {
        service = NetworkCacheService(localStore: CoreDataLocalStore(moc: moc), remoteStore: RemoteStore())
    }
    
    func downloadImage_old(at: URL) -> AnyPublisher<UIImage, URLError> {
        // NetworkCacheViewModel.loadImage(url: at)
        return URLSession.shared.dataTaskPublisher(for: at)
                .compactMap { UIImage(data: $0.data) }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
    }
    
    func downloadImage_new(at: URL) -> AnyPublisher<UIImage, Error> {
        return service
            .loadData(url: at.absoluteString)
            .compactMap { UIImage(data: $0) }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func downloadAllImages() -> DownloadImageEventEnumStream {
        func processImage(url: URL,
                          index: Int,
                          total: Int) -> DownloadImageEventEnumStream
        {
            return downloadImage_new(at: url)
                .print()
                .map{ _ -> Result<DownloadEventEnum, Error> in
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
            return Just(DownloadEventEnum
                            .cancelled
                            .asResult()
            ).eraseToAnyPublisher()
        }
        
        let pilotURLs = buildImagesUrls(imageType: .pilots)
        let upgradeURLs = buildImagesUrls(imageType: .upgrades)
        let urls: [URL] = pilotURLs + upgradeURLs
        
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

extension ImageService {
    private var pilotsBaseURL: String {
        return "https://pakirby1.github.io/images/XWing/pilots/"
    }
    
    private var upgradesBaseURL: String {
        return "https://pakirby1.github.io/images/XWing/upgrades/"
    }
    
    
    /// returns
    ///     ["first-order/tie-fo-fighter.json",
    ///     "galactic-empire/tie-rb-heavy.json"]
    private func readRecursive(subDirectory: String) -> [String] {
        guard let directoryURL = URL(string: subDirectory, relativeTo: Bundle.main.bundleURL) else {
            return []
        }
        
        var ret: [String] = []
        
        print(directoryURL.path)
        
        if let enumerator =
            FileManager.default.enumerator(atPath: directoryURL.path)
        {
            for case let path as String in enumerator {
                // Skip entries with '_' prefix, for example
                if path.hasSuffix("json") {
                    ret.append(path)
                }
            }
        }
        
        return ret
    }
    
    /// Build a list of URLs for all Images
    /// - Parameter directory: either "pilots" or "upgrades"
    private func buildImagesUrls(imageType: DownloadImageDirectory) -> [URL] {
        func buildFileURLs() -> [URL] {
            // get all files in Bundle/Data/Pilots and sub directories
            let files = readRecursive(subDirectory: imageType.description)
            let urls: [URL] = files.map{ URL(string: $0)! }
            
            return urls
        }
        
        func buildXWS(file: URL) throws -> [String] {
            // get the xws for each pilot from JSON file
            guard let directoryURL = URL(string: imageType.description, relativeTo: Bundle.main.bundleURL) else {
                return []
            }
            
            let path = directoryURL.appendingPathComponent(file.absoluteString)
            var xwsArr: [String] = []
            
            do {
                let data = try Data(contentsOf: path)
                let json = try JSON(data: data)
                
                switch(imageType) {
                    case .pilots:
                        xwsArr = json["pilots"].arrayValue.map { $0["xws"].stringValue }
                    
                    case .upgrades:
                        xwsArr = json["xws"].arrayValue.map { $0["xws"].stringValue }
                }
                
                return xwsArr
            } catch {
                throw DownloadURLsError.fileDecodingFailed(name: path.absoluteString, error)
            }
        }
        
        func buildImagesURLs(xwsArr: [String]) -> [URL] {
            // are we building a pilot or upgrade URL?
            return xwsArr.compactMap{ xws -> URL? in
                let url = "\(pilotsBaseURL)\(xws).png"
                return URL(string: url)
            }
        }
        
        var imagesURLs: [URL] = []
        let fileUrlPublisher: Publishers.Sequence<[URL], Never>  = buildFileURLs().publisher
        var cancellables = Set<AnyCancellable>()
        
        fileUrlPublisher.map{ fileURL -> [URL] in
            do {
                let xwsArr = try buildXWS(file: fileURL)
                let urls = buildImagesURLs(xwsArr: xwsArr)
                
                return urls
            } catch {
                return []
            }
            
        }
        .print()
        .sink(receiveValue: { imagesURLs.append(contentsOf: $0) })
        .store(in: &cancellables)
        
        return imagesURLs
    }
}

// MARK:- enums
enum DownloadURLsError: Swift.Error {
    case fileNotFound(name: String)
    case fileDecodingFailed(name: String, Swift.Error)
}

enum DownloadImageDirectory: CustomStringConvertible {
    case pilots
    case upgrades
    
    var description: String {
        switch(self) {
            case .pilots: return "pilots"
            case .upgrades: return "upgrades"
        }
    }
}
