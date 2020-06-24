//
//  Images.swift
//  DialControl
//
//  Created by Phil Kirby on 6/23/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import CoreData

//@objc(ImageData)
public class ImageData: NSManagedObject, Identifiable {
    @NSManaged public var url: String?
    
    public var id: UUID = UUID()
    
    static func == (lhs: ImageData, rhs: ImageData) -> Bool {
        lhs.id == rhs.id
    }
}

extension ImageData {
    static func fetchAll() -> NSFetchRequest<ImageData> {
        let request: NSFetchRequest<ImageData> = ImageData.fetchRequest() as! NSFetchRequest<ImageData>
        
        request.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
          
        return request
    }
}

extension ImageData {
    public override var description: String {
        return String(format: "\(String(describing: url))")
  }
}
