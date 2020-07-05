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
import CoreData

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
    
//    let printer: DeallocPrinter
    private let service: INetworkCacheService
    private var cancellables = Set<AnyCancellable>()
    private var cache = [String:UIImage]()
    var classFuncString: String = ""
    let id = UUID()
    
    init(service: INetworkCacheService = NetworkCacheService(localStore: LocalStore(), remoteStore: RemoteStore())) {
//        printer = DeallocPrinter("NetworkCacheViewModel \(id)")
        self.service = service
        print("allocated \(self) \(id)")
    }
    
    convenience init(moc: NSManagedObjectContext) {
        self.init(service: NetworkCacheService(localStore: CoreDataLocalStore(moc: moc), remoteStore: RemoteStore()))
        print("convenience \(self).init")
//        print("allocated \(self) \(id)")
    }
    
    deinit {
        print("\(self).deinit")
        print("deallocated \(self) \(id)")
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
                    case .localMiss(let url):
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
        
        /// have to add [weak self] in closure to avoid retain cycle between sink and self
        func loadImage() {
            service
                .loadData(url: url)
                .lane("PAK.NetworkCacheViewModel.loadData")
                .receive(on: RunLoop.main)
                .lane("PAK.NetworkCacheViewModel.receive")
                .sink(receiveCompletion: { [weak self] complete in
                    print("\(Date()) \(self).\(#function) received completion event")
                    
                    switch complete {
                    case .failure(let error):
                        if let storeError = error as? StoreError {
                            switch storeError {
                            case .localMiss(let url):
                                let message = "No Image in local cache for: \n \(url)"
                                self?.message = message
                                print("\(Date()) \(self).\(#function) \(message)")
                            case .remoteMiss:
                                let message = "No Image found in remote for: \(url)"
                                self?.message = message
                                print("\(Date()) \(self).\(#function) \(message)")
                            }
                        }
                        
                    case .finished:
                        print("\(Date()) \(self).\(#function) finished")
                    }
                },
                      receiveValue: { [weak self] value in
                          if let image = UIImage(data: value) {
                            self?.image = image
                            self?.message = url
                          }
                      })
                .store(in: &cancellables)
        }
        
        loadImage()
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
