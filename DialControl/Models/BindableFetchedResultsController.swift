//
//  BindableFetchedResultsController.swift
//  DialControl
//
//  Created by Phil Kirby on 12/17/19.
//  Copyright © 2019 SoftDesk. All rights reserved.
//

import Foundation
import CoreData
import Combine
import SwiftUI

// From: https://www.mattmoriarity.com/observing-core-data-changes-with-combine/getting-started/

class BindableFetchedResultsController<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    let fetchedResultsController: NSFetchedResultsController<T>

    // Publisher.  clients should reference to get updates
    @Published var fetchedObjects: [T]
    
    private var cancellableSet = Set<AnyCancellable>()
    
    private func updateFetchedObjects() {
        self.fetchedObjects = fetchedResultsController.fetchedObjects ?? []
    }
    
    init(
        fetchRequest: NSFetchRequest<T>,
        managedObjectContext: NSManagedObjectContext
    ) {
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: fetchRequest,
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
        
        fetchedObjects = fetchedResultsController.fetchedObjects ?? []
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        $fetchedObjects
            .print("PAK: BindableFetchedResultsController.fetchedObjects")
            .sink{ fetchedObjects in
                print("PAK: BindableFetchedResultsController.fetchedObjects event \(Date())")
                print("PAK: BindableFetchedResultsController.fetchedObjects count: \(fetchedObjects.count)")
            }
            .store(in: &cancellableSet)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("xyz: controllerDidChangeContent")
        updateFetchedObjects()
    }
    
    func fetch() -> AnyPublisher<[T], Never> {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
        
        fetchedObjects = fetchedResultsController.fetchedObjects ?? []
        return $fetchedObjects.eraseToAnyPublisher()
    }
}
