//
//  NetworkCache.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

// MARK: - NetworkCacheViewModel
// Workaround for https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
protocol INetworkCacheViewModel {
    func loadImage(url: String)
    var image: UIImage { get }
    var imagePublished: Published<UIImage> { get }
    var imagePublisher: Published<UIImage>.Publisher { get }
}

class NetworkCacheViewModel: ObservableObject, IPrintLog {
    @Published var image: UIImage = UIImage()
    @Published var message = "Placeholder Image"
    
    private let service: INetworkCacheService
    private var cancellable: AnyCancellable?
    private var cache = [String:UIImage]()
    var classFuncString: String = ""
    
    init(service: INetworkCacheService = NetworkCacheService(localStore: LocalStore(), remoteStore: RemoteStore())) {
        self.service = service
    }
    
    deinit {
        print("\(self).deinit")
    }
    
    var imagePublished: Published<UIImage> { _image }
    var imagePublisher: Published<UIImage>.Publisher { $image }
}

extension NetworkCacheViewModel {
    func loadImage(url: String) {
        func processCompletion(complete: Subscribers.Completion<Error>) {
            print("\(Date()) \(self).\(#function) received completion event")
            
            switch complete {
            case .failure(let error):
                if let storeError = error as? StoreError {
                    switch storeError {
                    case .cacheMiss(let url):
                        let message = "No Image in local cache for: \n \(url)"
                        self.message = message
                        print("\(Date()) \(self).\(#function) \(message)")
                    case .remoteMiss:
                        let message = "No Image found in remote for: \(url)"
                        self.message = message
                        print("\(Date()) \(self).\(#function) \(message)")
                    }
                }
                
            case .finished:
                print("\(Date()) \(self).\(#function) finished")
            }
        }
        
        func processReceivedValue(value: Data) {
            self.printLog("received value")
            
            if let image = UIImage(data: value) {
                self.image = image
                self.message = url
                self.cache[url] = image
                self.printLog("cached \(url)")
            }
        }
        
        self.cancellable = service
            .loadData(url: url)
            .lane("PAK.NetworkCacheViewModel.loadData")
            .receive(on: RunLoop.main)
            .lane("PAK.NetworkCacheViewModel.receive")
            .sink(receiveCompletion: processCompletion,
                  receiveValue: processReceivedValue)
    }
}

extension Just {
    var asFuture: Future<Output, Never> {
        .init { promise in
            promise(.success(self.output))
        }
    }
}
//let future: Future<Int, Never> = Just(1).asFuture
