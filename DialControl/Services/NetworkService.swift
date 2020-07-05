//
//  NetworkService.swift
//  DialControl
//
//  Created by Phil Kirby on 6/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
import Foundation
import Combine

// MARK: - NetworkCacheService
protocol INetworkCacheService {
    func loadData(url: String) -> AnyPublisher<Data, Error>
}

class NetworkCacheService<Local: ILocalStore, Remote: IRemoteStore> : INetworkCacheService, IPrintLog where Local.LocalObject == Remote.RemoteObject
{
    var classFuncString: String = ""
    let localStore: Local
    let remoteStore: Remote
//    private var cancellable: AnyCancellable?
    let id = UUID()
    
    init(localStore: Local, remoteStore: Remote, label: String = "") {
        self.localStore = localStore
        self.remoteStore = remoteStore
        print("\(Date()) \(label) NetworkCacheService.init")
        print("allocated \(self) \(id)")
    }
    
    deinit {
        print("\(Date()) NetworkCacheService.deinit")
        print("deallocated \(self) \(id)")
    }
    
    /// if data is in local cache, return data
    /// else if data is not in local cache
    ///     if data is found remote, return data
    ///     else if data in not in remote, return StoreError.remoteMiss
    func loadData(url: String) -> AnyPublisher<Data, Error> {
        self.classFuncString = "\(self).\(#function)"
        var localData: Bool = false
        print("\(Date()) \(self.classFuncString)")
        
        // see if the image is in the local store
        return self.localStore
            .loadData(url: url)
            .map { data in
                print("local data")
                localData = true
                return data
            }
            .catch { error in
                /// If an error was encountered reading from the local store, eat the error and attempt to read from the remote store
                /// we will return a new publisher (Future<Data, Error>) that contains either the data or a remote error
                self.remoteStore.loadData(url: url)
            }
            .print()
            .map { result -> Data in
                /// Did the result come from the local or Remote Store??  I can't tell...
                print("Success: \(result)")
                let data = result as! Data
                
                // write to the cache, only if it was sourced from the remoteStore
                if (!localData) {
                    self.localStore.saveData(key: url, value: data)
                }
                
                return data
            }
            .print()
            .eraseToAnyPublisher()
    }
}

