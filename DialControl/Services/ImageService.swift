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

class ImageService : ObservableObject, UrlBuildable {
    @Published var currentImage: DownloadImageEvent?
    private var cancellables = Set<AnyCancellable>()
    
    func downloadImage(at: URL) -> AnyPublisher<UIImage, URLError> {
        return URLSession.shared.dataTaskPublisher(for: at)
                .compactMap { UIImage(data: $0.data) }
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
    }
    
    func downloadAllImages() {
        let urls = buildImagesUrls().compactMap{ URL(string: $0) }
        let pub: AnyPublisher<URL, Never> = urls.publisher.eraseToAnyPublisher()
        var index: Int = 0
        let delay: Int = 2
        
        // buildImagesUrls()
        // .publisher.flatMap(maxPublishers: .max(1)) { url ->
        pub.flatMap(maxPublishers: .max(1)) { url -> AnyPublisher<DownloadImageEvent, Never> in
            print("\(#function) \(url)")
            index += 1
            
            // download & create event
            return self.downloadImage(at: url)
                .print()
                .replaceError(with: UIImage())
                .map{ _ in DownloadImageEvent(
                        index: index,
                        total: urls.count,
                        url: url.absoluteString) }
                .delay(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(delay)),
                       scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        .sink(receiveValue: {
            self.currentImage = $0
        }).store(in: &cancellables)
    }
    
    func cancel() {
        currentImage = nil
        cancellables.removeAll()
    }
    
    func downloadAllImages() -> AnyPublisher<DownloadImageEvent, Never> {
        let urls = buildImagesUrls().compactMap{ URL(string: $0) }
        let pub: AnyPublisher<URL, Never> = urls.publisher.eraseToAnyPublisher()
        var index: Int = 0
        let delay: Int = 2
        
        // buildImagesUrls()
        // .publisher.flatMap(maxPublishers: .max(1)) { url ->
        return pub.flatMap(maxPublishers: .max(1)) { url -> AnyPublisher<DownloadImageEvent, Never> in
            print("\(#function) \(url)")
            index += 1
            
            // download & create event
            return self.downloadImage(at: url)
                .print()
                .replaceError(with: UIImage())
                .map{ _ in DownloadImageEvent(
                        index: index,
                        total: urls.count,
                        url: url.absoluteString) }
                .delay(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(delay)),
                       scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
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


struct DownloadImageEvent: CustomStringConvertible {
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
