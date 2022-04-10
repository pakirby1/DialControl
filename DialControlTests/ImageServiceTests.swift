//
//  ImageServiceTests.swift
//  DialControlTests
//
//  Created by Phil Kirby on 7/7/21.
//  Copyright © 2021 SoftDesk. All rights reserved.
//

import XCTest
import Combine
import CoreData
@testable import DialControl

class ImageServiceTests: XCTestCase {

    func testDownloadAllImages() {
        let expectation = XCTestExpectation(description: self.debugDescription)

        var receiveCount = 0
        var collectedSequence: [Result<DownloadEventEnum, Error>] = []
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Used only if we have a unique constraint on our CoreData entity?
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let service = ImageService(moc: moc)
        
        let cancellable = service
            .downloadAllImages()
            .sink(receiveCompletion: { completion in
                print(".sink() received the completion", String(describing: completion))
                
                switch completion {
                case .finished:
                    print("finished")
                    break
                case .failure(let anError):
                    XCTFail("No failure should be received from empty")
                    print("received error: ", anError)
                    break
                }
                expectation.fulfill()
            }, receiveValue: { value in
                receiveCount += 1
                collectedSequence.append(value)
                print(".sink() data received \(value)")
            })
        
        wait(for: [expectation], timeout: 60.0)
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(receiveCount, 4)
//        XCTAssertEqual(collectedSequence, initialSequence)
    }
}

