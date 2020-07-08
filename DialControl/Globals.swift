//
//  Globals.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI

var shipLookupTable: [String:PilotFileUrl] = [:]

func loadJSON(fileName: String, directoryPath: String) -> String {
    if let path = Bundle.main.path(forResource: fileName,
                                   ofType: "",
                                   inDirectory: directoryPath)
    {
        print("path: \(path)")
        
        do {
            let json = try String(contentsOfFile: path)
            print("jsonData: \(shipJSON)")
            return json
        } catch {
            print("error reading from \(path)")
            return ""
        }
    }
    
    return ""
}

func fetchImageFromURL(urlString: String) -> UIImage {
    var image: UIImage? = nil
    
    let url = URL(string: urlString)!

    // Synchronous download using Data & String
    do {
        // get the content as String synchronously
//        let content = try String(contentsOf: url)
//        print(content)

        // get the content of the url as Data synchronously
        let data = try Data(contentsOf: url)
        image = UIImage(data: data)
    }
    catch {
        print(error.localizedDescription)
    }
    
    return image!
}
