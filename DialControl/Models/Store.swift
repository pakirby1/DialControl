//
//  Store.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import Combine

// MARK: - Local Store
protocol ILocalStore {
    associatedtype LocalObject
    func loadData(url: String) -> AnyPublisher<LocalObject, Error>
    func saveData(key: String, value: Data)
}

class LocalStore : ILocalStore {
    private var cache = [String:Data]()
    
    func loadData(url: String) -> AnyPublisher<Data, Error> {
        Future<Data, Error> { promise in
            if let keyValue = self.cache.first(where: { tuple -> Bool in
                return tuple.key == url ? true : false
            }) {
                promise(.success(keyValue.value))
            } else {
                promise(.failure(StoreError.cacheMiss(url)))
            }
        }.eraseToAnyPublisher()
    }
    
    func saveData(key: String, value: Data) {
        self.cache[key] = value
    }
}

class CoreDataLocalStore : ILocalStore {
    func loadData(url: String) -> AnyPublisher<Data, Error> {
        // bindableFRC.fetch(predicate: url)
        Just(Data()).tryMap{ data in
            guard data.count > 0 else {
                throw StoreError.cacheMiss(url)
            }
            
            return data
        }.eraseToAnyPublisher()
    }
    
    func saveData(key: String, value: Data) {
        // bindableFRC.moc.save()
    }
}

// MARK: - Remote Store
protocol IRemoteStore {
    associatedtype RemoteObject
    func loadData(url: String) -> Future<RemoteObject, Error>
}

struct RemoteStore : IRemoteStore {
    func loadData(url: String) -> Future<Data, Error> {
        let future = Future<Data, Error> { promise in
            let u = URL(string: url)!
            
            URLSession.shared.dataTask(with: u) { data, response, err in
                do {
                    if let error = err {
                        throw StoreError.remoteMiss("\(error)")
                    }
                    
                    guard let data = data else {
                        throw StoreError.remoteMiss("No data was received")
                    }
                    
                    promise(.success(data))
                } catch {
                    promise(.failure(error))
                }
            }.resume()
        }
        
        return future
    }
}

// MARK:- Error
enum StoreError : Error {
    case cacheMiss(String)
    case remoteMiss(String)
}
