//
//  Store.swift
//  DialControl
//
//  Created by Phil Kirby on 6/21/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
import Foundation
import CoreData
import Combine
import UIKit

// MARK: - Local Store
protocol ILocalStore {
    associatedtype LocalObject
    func loadData(url: String) -> AnyPublisher<LocalObject, Error>
    func saveData(key: String, value: Data)
}

class LocalStore : ILocalStore {
    private var cache = [String:Data]()
    let id = UUID()
    
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

struct CoreDataLocalStore : ILocalStore {
    let moc: NSManagedObjectContext
    let printer: DeallocPrinter
    let id = UUID()
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
        printer = DeallocPrinter("CoreDataLocalStore \(id)")
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

struct RemoteWebStore : IRemoteStore {
    let printer: DeallocPrinter
    let id = UUID()
    
    init() {
        printer = DeallocPrinter("RemoteStore \(id)")
    }
    
    // url https://pakirby1.github.io/images/XWing/pilots/herasyndulla-rz1awing.png
    func loadData(url: String) -> Future<Data, Error> {
        let future = Future<Data, Error> { promise in
            if let u = URL(string: url) {
                URLSession.shared.dataTask(with: u) { data, response, err in
                    do {
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw StoreError.remoteMiss("Invalid HTTP response code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
                        }
                        
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
        }
        
        return future
    }
}

struct AppBundleStore : IRemoteStore {
    let printer: DeallocPrinter
    let id = UUID()
    
    init() {
        printer = DeallocPrinter("AppBundleStore \(id)")
    }
    
    func getImage(name: String, type: String = "png") -> UIImage? {
        guard let pathToBundle = Bundle.main.path(forResource:"Images", ofType:"bundle"),
                let bundle = Bundle(path: pathToBundle),
              let path = bundle.path(forResource: name, ofType: type)
        else
        {
            return nil
        }
        
        return UIImage(contentsOfFile: path)
    }

    
    /*
    func gameImage(name: String, type: String = "png") -> UIImage? {
        guard let plugins = Bundle.main.builtInPlugInsPath,
              let bundle = Bundle(url: URL(fileURLWithPath:
                           plugins).appendingPathComponent("Game.bundle")),
              let path = bundle.path(forResource: name, ofType: type)
              else { return nil }
        return UIImage(contentsOfFile: path)
    }
     */
    
    /*
     Normally load using url: https://pakirby1.github.io/images/XWing/pilots/herasyndulla-rz1awing.png
     
     I think we want:
        pilots/herasyndulla-rz1awing.png
     
     convert "https://pakirby1.github.io/images/XWing/pilots/herasyndulla-rz1awing.png" into
     "pilots/herasyndulla-rz1awing", "png"
     
     */
    func loadData(url: String) -> Future<Data, Error> {
        /*
         convert "https://pakirby1.github.io/images/XWing/pilots/herasyndulla-rz1awing.png" into
         "pilots/herasyndulla-rz1awing", "png"
         */
        func convert(url: URL) -> (folderWithFile: String, fileExtension: String)? {
            func getFileComponents(file: String) -> (String, String) {
                return (file.fileName(), file.fileExtension()) // ("herasyndulla-rz1awing", "png")
            }
            
            let components = url.pathComponents  // ["/", "images", "XWing", "pilots", "herasyndulla-rz1awing.png"]
            
            if (components.count > 0) {
                let lastIndex = components.count - 1
                let filename = components[lastIndex]
                
                if filename.count > 0 {
                    let fileComponents = getFileComponents(file: filename)   // ("herasyndulla-rz1awing", "png")
                    let folder = components[lastIndex - 1] // "pilots"
                    return (folder + "/" + fileComponents.0, fileComponents.1)
                }
            }
            
            return nil
        }
        // Image(uiImage: UIImage(named: "yourImage")!)
        // Image(uiImage: UIImage(named: "BundleNameCreatedAbove.bundle"))
        
        /*
         if let fileURL = Bundle.main.url(forResource: "some-file", withExtension: "txt") {
             // we found the file in our bundle!
         
             if let fileContents = try? String(contentsOf: fileURL) {
                 // we loaded the file into a string!
         }
         }
         */
        let future = Future<Data, Error> { promise in
            if let u = URL(string: url) {
                do {
                    if let components = convert(url: u) {
                        let image = getImage(name: components.folderWithFile, type: components.fileExtension)
                        
                        guard let data = image?.pngData() else {
                            throw StoreError.remoteMiss("No data was received")
                        }
                        
                        promise(.success(data))
                    } else {
                        throw StoreError.remoteMiss("Invalid url: \(url)")
                    }
                } catch {
                    promise(.failure(error))
                }
            }
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

