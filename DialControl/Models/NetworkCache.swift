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

//protocol ViewModelProtocol {
//
//    // Define name (wrapped value)
//    var name: String { get }
//    
//    // Define name Published property wrapper
//    var namePublished: Published<String> { get }
//    
//    // Define name publisher
//    var namePublisher: Published<String>.Publisher { get }
//}
//
//class MyViewModel: ViewModelProtocol {
//
//    @Published var name: String
//    var namePublished: Published<String> { _name }
//    var namePublisher: Published<String>.Publisher { $name }
//
//    // ... ...
//    // ... ...
//    // ... ...
//}

class NetworkCacheViewModel: ObservableObject, IPrintLog {
    @Published var image: UIImage = UIImage()
    @Published var message = "Placeholder Image"
    
    private let service: INetworkCacheService
    private var cancellable: AnyCancellable?
    private var cache = [String:UIImage]()
    var classFuncString: String = ""
    @Published var test = UIImage()
    
    init(service: INetworkCacheService = NetworkCacheService(localStore: LocalStore(), remoteStore: RemoteStore())) {
        self.service = service
    }
    
    deinit {
        print("\(self).deinit")
    }
    
    var imagePublished: Published<UIImage> { _image }
    var imagePublisher: Published<UIImage>.Publisher { $image }
}

extension NetworkCacheViewModel : INetworkCacheViewModel {
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
            .sink(receiveCompletion: { completion in
                print("PAK.NetworkCacheViewModel.loadData received completion")
            }, receiveValue: { value in
                print("PAK.NetworkCacheViewModel.loadData received value")
            })
//            .sink(receiveCompletion: processCompletion,
//                  receiveValue: processReceivedValue)
    }
}

// MARK: - NetworkCacheService
protocol INetworkCacheService {
    func loadData(url: String) -> AnyPublisher<Data, Error>
}

class NetworkCacheService<Local: ILocalStore, Remote: IRemoteStore> : INetworkCacheService, IPrintLog where Local.LocalObject == Remote.RemoteObject
{
    var classFuncString: String = ""
    let localStore: Local
    let remoteStore: Remote
    private var cancellable: AnyCancellable?
    
    init(localStore: Local, remoteStore: Remote) {
        self.localStore = localStore
        self.remoteStore = remoteStore
    }
    
    /// if data is in local cache, return data
    /// else if data is not in local cache
    ///     if data is found remote, return data
    ///     else if data in not in remote, return StoreError.remoteMiss
    func loadData(url: String) -> AnyPublisher<Data, Error> {
        self.classFuncString = "\(self).\(#function)"
        
        // see if the image is in the local store
        return self.localStore
            .loadData(url: url)
            .catch { error in
                /// If an error was encountered reading from the local store, eat the error and attempt to read from the remote store
                /// we will return a new publisher (Future<Data, Error>) that contains either the data or a remote error
                // .catch { error -> Future<Data, Error> in
                /// Instance method 'catch' requires the types 'Local.LocalObject' and 'Data' be equivalent
                /// Cannot convert value of type 'Future<Local.LocalObject, Error>' to closure result type 'Future<Data, Error>'
                self.remoteStore.loadData(url: url)
            }
            .map { result -> Data in
                print("Success: \(result)")
                let data = result as! Data
                
                // write to the cache
                self.localStore.saveData(key: url, value: data)
                return data
            }
            .print()
            .eraseToAnyPublisher()
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
