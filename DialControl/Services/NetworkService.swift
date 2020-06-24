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

