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

class ShipViewModel: ObservableObject {
    let squadPilot: SquadPilot
    var ship: Ship? = nil
    
    init(squadPilot: SquadPilot) {
        self.squadPilot = squadPilot
        self.ship = self.getShip(shipName: squadPilot.ship,
            pilotName: squadPilot.name).0
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
    
    func getUpgradeImageUrl(upgrade: UpgradeSummary) -> String
    {
        func getJSON(forType: String) -> String {
            // Read json from file: forType.json
            let jsonFileName = "\(forType)"
            var upgradeJSON = ""
            
            if let path = Bundle.main.path(forResource: jsonFileName,
                                           ofType: "json",
                                           inDirectory: "upgrades")
            {
                print("path: \(path)")
                
                do {
                    upgradeJSON = try String(contentsOfFile: path)
                    print("upgradeJSON: \(upgradeJSON)")
                } catch {
                    print("error reading from \(path)")
                }
            }
            
//            return modificationsUpgradesJSON
            return upgradeJSON
        }
        
        func new(upgrade: UpgradeSummary) -> String {
            var imageUrl = ""
            
            let jsonString = getJSON(forType: upgrade.type)
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
            let matches = upgrades.filter({ $0.xws == upgrade.name })
            
            if (matches.count > 0) {
                let sides = matches[0].sides
                
                if (sides.count > 0) {
                    imageUrl = sides[0].image
                }
            }
            
            return imageUrl
        }
        
        func old(upgrade: UpgradeSummary) -> String {
            return "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_70.png"
        }
        
        return new(upgrade: upgrade)
    }
    
    var shipLookupTable: [String:PilotFileUrl] = [
        "alphaclassstarwing" : PilotFileUrl(fileName: "alpha-class-star-wing", directoryPath: "pilots/galactic-empire"),
        "tieskstriker" : PilotFileUrl(fileName: "tie-sk-striker", directoryPath: "pilots/galactic-empire"),
        "tieadvancedx1" : PilotFileUrl(fileName:"tie-advanced-x1", directoryPath: "pilots/galactic-empire"),
        "tieininterceptor" : PilotFileUrl(fileName:"tie-in-interceptor", directoryPath: "pilots/galactic-empire")
    ]
    
    var force: Int {
        return ship?
            .pilots
            .filter{ $0.xws == squadPilot.name}[0]
            .force?.value ?? 0
    }
    
    var charges: Int {
        return ship?
            .pilots
            .filter{ $0.xws == squadPilot.name }[0]
            .charges?.value ?? 0
    }
    
    var shields: Int {
        if ((ship?.stats.filter{ $0.type == "shields"}.count ?? 0) > 0) {
            return ship?
                .stats.filter{ $0.type == "shields" }[0].value ?? 0
        } else {
            return 0
        }
    }
    
    var dial: [String] {
        return self.ship?.dial ?? []
    }
}

struct ShipView: View {
    let viewModel: ShipViewModel
    @EnvironmentObject var viewFactory: ViewFactory
    @State var currentManeuver: String = ""
    @State var showCardOverlay: Bool = false
    @State var showImageOverlay: Bool = false
    @State var imageOverlayUrl: String = ""
    let theme: Theme = WestworldUITheme()
    
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
    
    init(viewModel: ShipViewModel) {
        self.viewModel = viewModel
    }

    var backButtonView: some View {
        Button(action: {
            self.viewFactory.viewType = .squadView
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Back to Squad")
                    .foregroundColor(theme.TEXT_FOREGROUND)
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
            
            PilotDetailsView(pilot: viewModel.squadPilot, displayUpgrades: true, displayHeaders: false)
                .padding(2)
                .border(Color.green, width: 2)
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .top) {
            Image(uiImage: fetchImageFromURL(urlString: viewModel.getShipImageUrl(shipName: viewModel.squadPilot.ship,
                                                                            pilotName: viewModel.squadPilot.name)))
                    .resizable()
                    .frame(width: 350.0,height:500)
                    .border(Color.green, width: 2)
                    .onTapGesture { self.showCardOverlay.toggle() }
                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                
                VStack(spacing: 20) {
                    if (viewModel.force > 0) {
                        LinkedView(maxCount: viewModel.force, type: StatButtonType.force)
                    }
                    
                    if (viewModel.charges > 0) {
                        LinkedView(maxCount: viewModel.charges, type: StatButtonType.charge)
                    }
                    
                    if (viewModel.shields > 0) {
                        LinkedView(maxCount: viewModel.shields, type: StatButtonType.shield)
                    }
                }.border(Color.green, width: 2)

                DialView(temperature: 0,
                     diameter: 400,
                     currentManeuver: $currentManeuver,
                     dial: self.viewModel.dial,
                     displayAngleRanges: false)
                .frame(width: 400.0,height:400)
                    .border(theme.BORDER_ACTIVE, width: 2)
            }
    }
    
    func footer(showImageOverlay: Binding<Bool>) -> some View {
        UpgradesView(upgrades: viewModel.squadPilot.upgrades.modifications + viewModel.squadPilot.upgrades.sensors + viewModel.squadPilot.upgrades.talents,
            showImageOverlay: $showImageOverlay).environmentObject(viewModel)
    }
    
    func footer_New(showImageOverlay: Binding<Bool>) -> some View {
//        UpgradesView(upgrades: viewModel.squadPilot.upgrades.modifications + viewModel.squadPilot.upgrades.sensors + viewModel.squadPilot.upgrades.talents,
//            showImageOverlay: $showImageOverlay).environmentObject(viewModel)
        
        let modifications: [UpgradeSummary] = viewModel.squadPilot.upgrades.modifications.map {
            UpgradeSummary(type: "modification", name: $0)
        }
        
        let sensors: [UpgradeSummary] = viewModel.squadPilot.upgrades.sensors.map {
            UpgradeSummary(type: "sensor", name: $0)
        }
        
        let talents: [UpgradeSummary] = viewModel.squadPilot.upgrades.talents.map {
            UpgradeSummary(type: "talent", name: $0)
        }
        
        let upgrades = modifications + sensors + talents
        
        return UpgradesView_New(upgrades: upgrades,
                                showImageOverlay: $showImageOverlay,
                                imageOverlayUrl: $imageOverlayUrl)
            .environmentObject(self.viewModel)
    }
    
    func buildView() -> AnyView {
        return AnyView(VStack(alignment: .leading) {
            headerView
            bodyContent
//            footer(showImageOverlay: $showImageOverlay)
            footer_New(showImageOverlay: $showImageOverlay)
        }.border(Color.red, width: 2)
            .overlay(self.showImageOverlay == true ? upgradeImageOverlay(urlString: self.imageOverlayUrl) : AnyView(clearView))
            .onTapGesture{
                self.showImageOverlay = false
            }
        )
    }
    
    func upgradeImageOverlay(urlString: String) -> AnyView {
        return AnyView(
            ZStack {
                Color.gray.opacity(0.5)
                
                Image(uiImage: fetchImageFromURL(urlString: urlString))
            })
    }
    
    @State var displayOverlay: Bool = false
    
    var body: some View {
        buildView()
    }
}

struct PilotFileUrl: CustomStringConvertible {
    let fileName: String
    let directoryPath: String
    
    var description: String {
        return "fileName: '\(fileName)' directoryPath: '\(directoryPath)'"
    }
}

struct UpgradeSummary : Identifiable {
    let id = UUID()
    let type: String
    let name: String
}

struct UpgradesView: View {
    @State var imageName: String = ""
    let upgrades: [String]
    @Binding var showImageOverlay: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades, id:\.self) {
                    UpgradeView(name: $0,
                                showImageOverlay: self.$showImageOverlay)
                }
            }
        }
    }
}

struct UpgradesView_New: View {
    @EnvironmentObject var viewModel: ShipViewModel
    @State var imageName: String = ""
    let upgrades: [UpgradeSummary]
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades) {
                    UpgradeViewNew(upgrade: $0,
                                showImageOverlay: self.$showImageOverlay,
                                imageOverlayUrl: self.$imageOverlayUrl)
                        .environmentObject(self.viewModel)
                }
            }
        }
    }
}

struct UpgradeView: View {
    var name: String
    @Binding var showImageOverlay: Bool
    
    var body: some View {
        Text("\(name)")
            .foregroundColor(.white)
            .font(.largeTitle)
        //                        .frame(width: 200, height: 200)
            .padding(15)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                self.showImageOverlay = true
            }
    }
}

struct UpgradeViewNew: View {
    @EnvironmentObject var viewModel: ShipViewModel
    var upgrade: UpgradeSummary
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    let theme: Theme = WestworldUITheme()
    
    var body: some View {
        Text("\(upgrade.name)")
            .foregroundColor(theme.TEXT_FOREGROUND)
            .font(.largeTitle)
        //                        .frame(width: 200, height: 200)
            .padding(15)
//            .background(Color.red)
            .background(theme.BUTTONBACKGROUND)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                self.showImageOverlay = true
                self.imageOverlayUrl = self.viewModel.getUpgradeImageUrl(upgrade: self.upgrade)
            }
    }
}


struct ImageOverlay: View {
    @Binding var isShowing : Bool
    
    var body: some View {
        Text("Charge")
            .frame(width: 100, height: 100)
            .background(Color.yellow)
            .cornerRadius(20)
            .opacity(self.isShowing ? 1 : 0)
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

enum UpgradeCardEnum {
    case astromech(String)
    case cannon(String)
    case cargo(String)
    case command(String)
    case configuration(String)
    case crew(String)
    case device(String)
    case forcepower(String)
    case gunner(String)
    case hardpoint(String)
    case illicit(String)
    case missile(String)
    case modification(String)
    case sensor(String)
    case tacticalrelay(String)
    case talent(String)
    case team(String)
    case tech(String)
    case title(String)
    case torpedo(String)
    case turret(String)
}
