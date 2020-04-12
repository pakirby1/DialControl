//
//  ShipView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/25/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

struct ShipView: View {
    let squadPilot: SquadPilot
    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    @State var showCardOverlay: Bool = false
    
    let dial: [String] = [
                  "1TW",
                  "1YW",
                  "2TB",
                  "2BB",
                  "2FB",
                  "2NB",
                  "2YB",
                  "3LR",
                  "3TW",
                  "3BW",
                  "3FB",
                  "3NW",
                  "3YW",
                  "3PR",
                  "4FB",
                  "4KR",
                  "5FW"
                ]
    
    var backButtonView: some View {
        Button(action: {
            self.viewFactory.viewType = .squadView
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Back to Squad")
            }
        }.padding(5)
    }
    
    var clearView: some View {
        Color
            .clear
            .border(Color.red, width: 5)
    }
    
    var headerView: some View {
        HStack {
            HStack(alignment: .top) {
                backButtonView
                    .border(Color.blue, width: 2)
            }
            .frame(width: 150, height: 50, alignment: .leading)
            .border(Color.blue, width: 2)
            
            PilotDetailsView(pilot: squadPilot, displayUpgrades: true, displayHeaders: false)
                .padding(2)
                .border(Color.green, width: 2)
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .center) {
                Image(uiImage: fetchImageFromURL(urlString: getShipImageUrl(shipName: squadPilot.ship,
                                                                            pilotName: squadPilot.name)))
                    .resizable()
                    .frame(width: 350.0,height:500)
                    .border(Color.green, width: 2)
                    .onTapGesture { self.showCardOverlay.toggle() }
                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                
                VStack(spacing: 20) {
                    LinkedView(maxCount: 8, type: StatButtonType.force)
                    LinkedView(maxCount: 10, type: StatButtonType.charge)
                    LinkedView(maxCount: 32, type: StatButtonType.shield)
                }.border(Color.green, width: 2)

                DialView(temperature: 0, diameter: 400, currentManeuver: $currentManeuver, dial: dial, displayAngleRanges: false)
                    .frame(width: 400.0,height:400).border(Color.green, width: 2)
            }
    }
    
    var footer: some View {
        UpgradesView(upgrades: squadPilot.upgrades.modifications + squadPilot.upgrades.sensors + squadPilot.upgrades.talents)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            headerView
            bodyContent
            footer
        }.border(Color.red, width: 2)
    }
    
    func getShip(shipName: String, pilotName: String) -> (Ship, Pilot) {
        var shipJSON: String = ""
                
                print("shipName: \(shipName)")
                print("pilotName: \(pilotName)")
                
                if let pilotFileUrl = shipLookupTable[shipName] {
                    print("pilotFileUrl: \(pilotFileUrl)")
                    
                    if let path = Bundle.main.path(forResource: pilotFileUrl.fileName,
                                                   ofType: "json",
                                                   inDirectory: pilotFileUrl.directoryPath)
                    {
                        print("path: \(path)")
                        
                        do {
                            shipJSON = try String(contentsOfFile: path)
                            print("jsonData: \(shipJSON)")
                        } catch {
                            print("error reading from \(path)")
                        }
                    }
                }
                
                let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
                let foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0]
        
        return (ship, foundPilots)
    }
    
    
    //    "tieskstriker"
    func getShipImageUrl(shipName: String, pilotName: String) -> String {
        
        func buildUrl(shipName: String, pilotName: String) -> String {
            return getShip(shipName: shipName, pilotName: pilotName).1.image
        }
        
        func fetchImage(from urlString: String,
                        completionHandler: @escaping (_ data: Data?) -> ())
        {
            let session = URLSession.shared
            let url = URL(string: urlString)
                
            print("url: \(String(describing: url))")
            
            let dataTask = session.dataTask(with: url!) { (data, response, error) in
                if error != nil {
                    print("Error fetching the image! 😢")
                    completionHandler(nil)
                } else {
                    completionHandler(data)
                }
            }
                
            dataTask.resume()
        }
        
        let url = buildUrl(shipName: shipName, pilotName: pilotName)
        
//        fetchImage(from: foundPilots.image) { (imageData) in
//            if let data = imageData {
//                // referenced imageView from main thread
//                // as iOS SDK warns not to use images from
//                // a background thread
//                DispatchQueue.main.async {
//                    image = UIImage(data: data)
//                }
//            } else {
//                    // show as an alert if you want to
//                print("Error loading image");
//            }
//        }
        
//        print("image Url: \(pilot.image)")
        
//        let imageName = "" // your image name here
//        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
//        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        return url
    }
    
    var shipLookupTable: [String:PilotFileUrl] = [
        "alphaclassstarwing" : PilotFileUrl(fileName: "alpha-class-star-wing", directoryPath: "pilots/galactic-empire"),
        "tieskstriker" : PilotFileUrl(fileName: "tie-sk-striker", directoryPath: "pilots/galactic-empire"),
        "tieadvancedx1" : PilotFileUrl(fileName:"tie-advanced-x1", directoryPath: "pilots/galactic-empire"),
        "tieininterceptor" : PilotFileUrl(fileName:"tie-in-interceptor", directoryPath: "pilots/galactic-empire")
    ]
}

struct PilotFileUrl: CustomStringConvertible {
    let fileName: String
    let directoryPath: String
    
    var description: String {
        return "fileName: '\(fileName)' directoryPath: '\(directoryPath)'"
    }
}

struct UpgradesView: View {
    let upgrades: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades, id:\.self) {
                    Text("\($0)")
                        .foregroundColor(.white)
                        .font(.largeTitle)
//                        .frame(width: 200, height: 200)
                        .padding(15)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

struct TextOverlay: View {
    @Binding var isShowing : Bool
    
    var body: some View {
        Text("Charge")
            .frame(width: 100, height: 100)
            .background(Color.yellow)
            .cornerRadius(20)
            .opacity(self.isShowing ? 1 : 0)
    }
}

/*
 func asyncMethod(completion: ((String) -> Void)) {
     //...
 }

 func promisifiedAsyncMethod() -> AnyPublisher<String, Never> {
     Future<String, Never> { promise in
         asyncMethod { value in
             promise(.success(value))
         }
     }
     .eraseToAnyPublisher()
 }
 */

/// https://theswiftdev.com/how-to-download-files-with-urlsession-using-combine-publishers-and-subscribers/
/// https://www.vadimbulavin.com/asynchronous-swiftui-image-loading-from-url-with-combine-and-swift/
// Fetches an image from an url and publishes the UIImage
// on a Combine publisher
class ImageFetcher : ObservableObject {
    @Published var image: UIImage?
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    private var cancellable: AnyCancellable?
    
    deinit {
        cancellable?.cancel()
    }

    func load() {
        print("url: \(url.absoluteString)")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map {
                print("\($0.data.count)")
                return UIImage(data: $0.data)
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

// View that references the ImageFetcher
// let url = URL(string: "https://image.tmdb.org/t/p/original/pThyQovXQrw2m0s9x82twj48Jq4.jpg")!
// URLImageView(url: URL(string: "https://image.tmdb.org/t/p/original/pThyQovXQrw2m0s9x82twj48Jq4.jpg")!, view: Text("Loading.."))
struct URLImageView<T: View>: View {
//    var url: URL
    @ObservedObject private var imageFetcher: ImageFetcher
    private let placeholder: T?

    private var image: some View {
        Group {
            if imageFetcher.image != nil {
                Image(uiImage: imageFetcher.image!)
                    .resizable()
            } else {
                placeholder
            }
        }
    }
    
    var body: some View {
        image.onAppear(perform: imageFetcher.load)
//        EmptyView()
    }
    
    init(url: URL, view: T? = nil) {
        self.imageFetcher = ImageFetcher(url: url)
        self.placeholder = view
    }
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

