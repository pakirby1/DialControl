//
//  Store.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import Combine
import CoreData

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
                promise(.failure(StoreError.localMiss(url)))
            }
        }.eraseToAnyPublisher()
    }
    
    func saveData(key: String, value: Data) {
        self.cache[key] = value
    }
}

class CoreDataLocalStore : ILocalStore {
    let moc: NSManagedObjectContext
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    func loadData(url: String) -> AnyPublisher<Data, Error> {
        return Future<Data, Error> { promise in
            do {
                let fetchRequest = ImageData.fetchAllWith(url: url)
                let fetchedObjects = try self.moc.fetch(fetchRequest)
                
                if let image = fetchedObjects.first {
                    if let data = image.data {
                        promise(.success(data))
                    } else {
                        throw StoreError.localMiss("missing data for \(url)")
                    }
                } else {
                    throw StoreError.localMiss("missing entity ImageData for \(url)")
                }
            } catch {
                print(error)
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func saveData(key: String, value: Data) {
        let imageData = ImageData(context: self.moc)
        imageData.url = key
        imageData.data = value
        
        do {
            try self.moc.save()
        } catch {
            print(error)
        }
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
    case localMiss(String)
    case remoteMiss(String)
}

struct PAKStoreError : Error {
    let wrappedValue: StoreError
    let currentValue: StoreError
}
