//
//  Images.swift
//  DialControl
//
//  Created by Phil Kirby on 6/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//
import UIKit
import Foundation
import CoreData

public class ImageData: NSManagedObject, Identifiable {
    @NSManaged public var url: String?
    @NSManaged public var data: Data?
    
    public var id: UUID = UUID()
    
    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
        lhs.id == rhs.id
    }
}

extension ImageData {
    static func deleteAll() {
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        let managedObjectContext = persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: ImageData.self))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try managedObjectContext.executeAndMergeChanges(using: deleteRequest)
        }
        catch {
            print(error)
        }
    }
    
    static func fetchAll() -> NSFetchRequest<ImageData> {
        let request: NSFetchRequest<ImageData> = ImageData.fetchRequest() as! NSFetchRequest<ImageData>
        
        request.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
          
        return request
    }
    
    static func fetchAllWith(url: String) -> NSFetchRequest<ImageData> {
        let request: NSFetchRequest<ImageData> = ImageData.fetchRequest() as! NSFetchRequest<ImageData>
        request.predicate = NSPredicate(format: "url == %@", url)
        request.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
          
        return request
    }
}

extension ImageData {
    public override var description: String {
        return String(format: "\(String(describing: url))")
  }
}

extension NSManagedObjectContext {
    /// https://www.avanderlee.com/swift/nsbatchdeleterequest-core-data/
    /// 
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
