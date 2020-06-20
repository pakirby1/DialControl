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
    var shipPilot: ShipPilot
    var ship: Ship? = nil
    @Published var shipImage: UIImage = UIImage()
    @Published var upgradeImage: UIImage = UIImage()
    private var _displayImageOverlay: Bool = false
    
    init(shipPilot: ShipPilot) {
        self.shipPilot = shipPilot
    }
    
    var displayImageOverlay: Bool {
        get {
            return _displayImageOverlay
        }
        set {
            _displayImageOverlay = newValue
        }
    }
    
    var imageUrl: String {
        getShip(shipName: shipPilot.shipName,
                       pilotName: shipPilot.pilotName).1.image
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
    
        return url
    }
    
    func getUpgradeImageUrl(upgrade: Upgrade) -> String
    {
        func getJSON(forType: String, inDirectory: String) -> String {
            // Read json from file: forType.json
            let jsonFileName = "\(forType)"
            var upgradeJSON = ""
            
            if let path = Bundle.main.path(forResource: jsonFileName,
                                           ofType: "json",
                                           inDirectory: inDirectory)
            {
                print("path: \(path)")
                
                do {
                    upgradeJSON = try String(contentsOfFile: path)
                    print("upgradeJSON: \(upgradeJSON)")
                } catch {
                    print("error reading from \(path)")
                }
            }
            
            return upgradeJSON
        }
        
        func getImageURLFromJSON_new(upgrade: Upgrade) -> String {
            var imageUrl = ""
            
            let type = upgrade.sides[0].type.lowercased()
            
            let jsonString = getJSON(forType: type, inDirectory: "upgrades")
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
            let matches = upgrades.filter({ $0.xws == upgrade.xws })
            
            if (matches.count > 0) {
                let sides = matches[0].sides
                
                if (sides.count > 0) {
                    imageUrl = sides[0].image
                }
            }
            
            return imageUrl
        }
        
        func getImageURLFromJSON_old(upgrade: UpgradeSummary) -> String {
            return "https://sb-cdn.fantasyflightgames.com/card_images/Card_Upgrade_70.png"
        }
        
        return getImageURLFromJSON_new(upgrade: upgrade)
    }
    
    var force: Int {
        return shipPilot.ship.pilots[0]
            .force?.value ?? 0
    }
    
    var charges: Int {
        return shipPilot.ship.pilots[0]
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

var shipLookupTable: [String:PilotFileUrl] = [
    "alphaclassstarwing" : PilotFileUrl(fileName: "alpha-class-star-wing", directoryPath: "pilots/galactic-empire"),
    "tieskstriker" : PilotFileUrl(fileName: "tie-sk-striker", directoryPath: "pilots/galactic-empire"),
    "tieadvancedx1" : PilotFileUrl(fileName:"tie-advanced-x1", directoryPath: "pilots/galactic-empire"),
    "tieininterceptor" : PilotFileUrl(fileName:"tie-in-interceptor", directoryPath: "pilots/galactic-empire"),
    "ut60duwing": PilotFileUrl(fileName:"ut-60d-u-wing", directoryPath: "pilots/rebel-alliance"),
    "sheathipedeclassshuttle": PilotFileUrl(fileName:"sheathipede-class-shuttle", directoryPath: "pilots/rebel-alliance"),
    "asf01bwing": PilotFileUrl(fileName:"a-sf-01-b-wing", directoryPath: "pilots/rebel-alliance")
]

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
            
            PilotDetailsView(shipPilot: viewModel.shipPilot,
                             displayUpgrades: true,
                             displayHeaders: false)
                .padding(2)
                .border(Color.green, width: 2)
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .top) {
            PAKImageView(url: viewModel.imageUrl)
                .frame(width: 350.0, height:500)
                .onTapGesture { self.showCardOverlay.toggle() }
                .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
            
//            Image(uiImage: fetchImageFromURL(urlString: viewModel.imageUrl))
//                    .resizable()
//                    .frame(width: 350.0,height:500)
//                    .border(Color.green, width: 2)
//                    .onTapGesture { self.showCardOverlay.toggle() }
//                    .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                
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
                     dial: self.viewModel.shipPilot.ship.dial,
                     displayAngleRanges: false)
                .frame(width: 400.0,height:400)
                    .border(theme.BORDER_ACTIVE, width: 2)
            }
    }
    
    func footer(showImageOverlay: Binding<Bool>) -> some View {
        UpgradesView(upgrades: viewModel.shipPilot.upgrades,
                     showImageOverlay: $showImageOverlay,
                     imageOverlayUrl: $imageOverlayUrl)
            .environmentObject(viewModel)
    }
    
    var imageOverlayView: AnyView {
        let defaultView = AnyView(clearView)
        
        print("UpgradeView var imageOverlayView self.showImageOverlay=\(self.showImageOverlay)")
        print("UpgradeView var imageOverlayView self.viewModel.displayImageOverlay=\(self.viewModel.displayImageOverlay)")
        
        if (self.viewModel.displayImageOverlay == true) {
            return upgradeImageOverlay(urlString: self.imageOverlayUrl)
        } else {
            return defaultView
        }
    }
    
    func buildView() -> AnyView {
        return AnyView(VStack(alignment: .leading) {
            headerView
            bodyContent
            footer(showImageOverlay: $showImageOverlay)
//            footer_New(showImageOverlay: $showImageOverlay)
        }.border(Color.red, width: 2)
            .overlay(imageOverlayView)
//            .onTapGesture{
//                self.showImageOverlay = false
//                self.viewModel.displayImageOverlay = false
//            }
        )
    }
    
    func upgradeImageOverlay(urlString: String) -> AnyView {
        return AnyView(
            ZStack {
                Color
                    .gray
                    .opacity(0.5)
                    .onTapGesture{
                        self.showImageOverlay = false
                        self.viewModel.displayImageOverlay = false
                    }
                
                PAKImageView(url: urlString)
                    .frame(width: 500.0, height:350)
//                Image(uiImage: fetchImageFromURL(urlString: urlString))
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
    let prettyName: String
}

struct UpgradesView: View {
    @EnvironmentObject var viewModel: ShipViewModel
    @State var imageName: String = ""
    let upgrades: [Upgrade]
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(upgrades) {
                    UpgradeView(viewModel: UpgradeView.UpgradeViewModel(upgrade: $0),
                                showImageOverlay: self.$showImageOverlay,
                                imageOverlayUrl: self.$imageOverlayUrl)
                        .environmentObject(self.viewModel)
                }
            }
        }
    }
}

struct UpgradeView: View {
    struct UpgradeViewModel {
        let upgrade: Upgrade
        
        var imageUrl: String {
            var imageUrl = ""
            
            let type = upgrade.sides[0].type.lowercased()
            
            let jsonString = getJSON(forType: type, inDirectory: "upgrades")
            
            let upgrades: [Upgrade] = Upgrades.serializeJSON(jsonString: jsonString)
            
            let matches = upgrades.filter({ $0.xws == upgrade.xws })
            
            if (matches.count > 0) {
                let sides = matches[0].sides
                
                if (sides.count > 0) {
                    imageUrl = sides[0].image
                }
            }
            
            return imageUrl
        }
    }
    
    let viewModel: UpgradeViewModel
    @Binding var showImageOverlay: Bool
    @Binding var imageOverlayUrl: String
    @EnvironmentObject var shipViewModel: ShipViewModel
    
    var body: some View {
        Text("\(self.viewModel.upgrade.name)")
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding(15)
            .background(Color.red)
//            .contentShape(RoundedRectangle(cornerRadius: 10))
//            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                print("\(Date()) UpgradeView.Text.onTapGesture \(self.viewModel.imageUrl)")
                self.showImageOverlay = true
                self.shipViewModel.displayImageOverlay = true
                self.imageOverlayUrl = self.viewModel.imageUrl
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

func getJSON(forType: String, inDirectory: String) -> String {
    // Read json from file: forType.json
    let jsonFileName = "\(forType)"
    var upgradeJSON = ""
    
    if let path = Bundle.main.path(forResource: jsonFileName,
                                   ofType: "json",
                                   inDirectory: inDirectory)
    {
        print("path: \(path)")
        
        do {
            upgradeJSON = try String(contentsOfFile: path)
            print("upgradeJSON: \(upgradeJSON)")
        } catch {
            print("error reading from \(path)")
        }
    }
    
    return upgradeJSON
}

struct PAKImageView: View {
    let url: String
    @ObservedObject var viewModel = PAKImageViewModel()
    
    var body: some View {
        Image(uiImage: viewModel.image)
            .resizable()
            .border(Color.green, width: 2)
            .onAppear {
                print("PAKImageView loadImage url: \(self.url)")
                self.viewModel.loadImage(url: self.url)
            }
    }
}

class PAKImageViewModel: ObservableObject {
    @Published var image: UIImage = UIImage()
    
    func loadImage(url: String) {
        self.image = fetchImageFromURL(urlString: url)
    }
}
