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
import CoreData

// MARK:- Globals
/// let dict: [String: PilotFileUrl] = [:]
/// foreach file in directoryPath {
///  let key = file.remove("-")
///  let pfu = PilotFileUrl(filename: file, directoryPath: directoryPath)
///  dict[key] = pfu
/// }

var shipLookupTable: [String:PilotFileUrl] = [:]

struct ShipLookupBuilder {
    static func buildUpgradeVariable(upgrade: String) {
        let plural = "\(upgrade)s"
        
        let template = """
            let \(plural) : [Upgrade] = upgrades
                .\(plural)
                .map{ getUpgrade(upgradeCategory: "\(upgrade)", upgradeName: $0) }
        
        """
        
        print(template)
    }

    static func buildPublicVar(upgrade: String) -> String {
        let publicVar = "var \(upgrade)s: [String] { return _\(upgrade) ?? [] }"
        return publicVar
    }
    
    static func buildPrivateVar(upgrade: String) -> String {
        let privateVar = "private var _\(upgrade): [String]?"
        return privateVar
    }
    
    static func buildCodingKey(upgrade: String) -> String {
        let codingKey = "case _\(upgrade) = \"\(upgrade)\""
        return(codingKey)
    }
    
    static func buildAllUpgradesText() {
        
        var allUpgrades: [String] = []
        var publicVars: [String] = []
        var privateVars: [String] = []
        var codingKeys: [String] = []
        
        
        
        for upgrade in UpgradeCardEnum.allCases {
            let formatted = "\(upgrade)".removeAll(character: "(\"\")")
           
            allUpgrades.append("allUpgrades.append(" + formatted + "s)")
           buildUpgradeVariable(upgrade: formatted)
           publicVars.append(buildPublicVar(upgrade: formatted))
           privateVars.append(buildPrivateVar(upgrade: formatted))
           codingKeys.append(buildCodingKey(upgrade: formatted))
        }
        
//        let allUpgrades = "allUpgrades " + UpgradeCardEnum.allCases.joined(separator: " + ")
//        allUpgrades = allUpgrades.removeAll(character: "(\"\")")
        
        print("\nSquadCardView.getShips()\n")
        allUpgrades.forEach{ print($0) }
        
        /// public vars
        print("\nSquadPilotUpgrade public vars\n")
        publicVars.forEach{ print($0) }
        
        print("\nSquadPilotUpgrade private vars\n")
        privateVars.forEach{ print($0) }
        
        print("\nSquadPilotUpgrade coding keys\n")
        codingKeys.forEach{ print($0) }
    }

    static func buildLookup() -> [String:PilotFileUrl] {
        var ret : [String:PilotFileUrl] = [:]
        let fm = FileManager.default
        let path = Bundle.main.resourcePath! + "/pilots"
        
        print(path)
        
        do {
            let dirs = try fm.contentsOfDirectory(atPath: path)

            for dir in dirs {
                print("\(dir)")
                let subDir = path + "/" + dir
                let files = try fm.contentsOfDirectory(atPath: subDir)
                
                for file in files {
                    print("\t\(file)")
                    let filename = file.fileName()  // tie-ln-fighter.json
                    var key = filename.removeAll(character: "-")    // tielnfighter
                    let directoryPath = "pilots/" + dir // rebel-alliance
                    
                    if dir == "rebel-alliance" {
                        key = "rebel" + key // rebeltielnfighter
                    }
                    
                    let pfu = PilotFileUrl(fileName: file,
                                           directoryPath: directoryPath)
                    ret[key] = pfu
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
            print(error)
        }
        
        return ret
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

extension String {
    func removeAll(character: String) -> String {
        return components(separatedBy: character).joined()
    }
}

private func loadJSON(fileName: String, directoryPath: String) -> String {
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

enum UpgradeCardEnum : CaseIterable {
    static var allCases: [UpgradeCardEnum] {
        return [.astromech(""),
        .cannon(""),
        .cargo(""),
        .command(""),
        .configuration(""),
        .crew(""),
        .device(""),
        .forcepower(""),
        .gunner(""),
        .hardpoint(""),
        .illicit(""),
        .missile(""),
        .modification(""),
        .sensor(""),
        .tacticalrelay(""),
        .talent(""),
        .team(""),
        .tech(""),
        .title(""),
        .torpedo(""),
        .turret("")]
    }

    
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

// MARK:- Ship view
class ShipViewModel: ObservableObject {
    var shipPilot: ShipPilot
    var squad: Squad
    @Published var shipImage: UIImage = UIImage()
    @Published var upgradeImage: UIImage = UIImage()
    private var _displayImageOverlay: Bool = false
    private var cancellable: AnyCancellable?
    
    // CoreData
    private let frc: BindableFetchedResultsController<ImageData>
    let moc: NSManagedObjectContext
    
    // Images Support
//    @ObservedObject var networkCacheViewModel: NetworkCacheViewModel
    @Published var images: [ImageData] = []
    
    init(moc: NSManagedObjectContext,
         shipPilot: ShipPilot,
         squad: Squad)
    {
        self.shipPilot = shipPilot
        self.squad = squad
        
        // CoreData
        self.moc = moc
        self.frc = BindableFetchedResultsController<ImageData>(fetchRequest: ImageData.fetchAll(),
            managedObjectContext: moc)

        // take the stream generated by the frc and @Published fetchedObjects
        // and assign it to
        // players.  This way clients don't have to access viewModel.frc.fetchedObjects
        // directly.  Use $ to geet access to the publisher of the @Published.
        self.cancellable = self.frc
            .$fetchedObjects
            .print()
            .receive(on: DispatchQueue.main)
            .assign(to: \ShipViewModel.images, on: self)
    }
    
    var displayImageOverlay: Bool {
        get {
            return _displayImageOverlay
        }
        set {
            _displayImageOverlay = newValue
        }
    }
    
    lazy var shipImageURL: String = {
        loadShipFromJSON(shipName: shipPilot.shipName,
                       pilotName: shipPilot.pilotName).1.image
    }()
    
    /// What do we return if we encounter an error (empty file)?
    func loadShipFromJSON(shipName: String, pilotName: String) -> (Ship, Pilot) {
        var shipJSON: String = ""
        
        print("shipName: \(shipName)")
        print("pilotName: \(pilotName)")
        
        if let pilotFileUrl = shipLookupTable[shipName] {
            print("pilotFileUrl: \(pilotFileUrl)")
            shipJSON = loadJSON(fileName: pilotFileUrl.fileName,
                                directoryPath: pilotFileUrl.directoryPath)
        }
        
        let ship: Ship = Ship.serializeJSON(jsonString: shipJSON)
        let foundPilots: Pilot = ship.pilots.filter{ $0.xws == pilotName }[0]
        
        return (ship, foundPilots)
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
        let ship = self.shipPilot.ship
        let shieldsStats: [Stat] = ship.stats.filter{ $0.type == "shields"}
        
        if (shieldsStats.count > 0) {
            return shieldsStats[0].value
        } else {
            return 0
        }
    }
    
    var dial: [String] {
        let ship = self.shipPilot.ship
        
        return ship.dial
    }
}

protocol IDeallocPrinter {
    var printer: DeallocPrinter { get set }
    var id: UUID { get }
}

class DeallocPrinter {
    let label: String
    
    init(_ label: String) {
        self.label = label
        print("allocated \(label)")
    }
    
    deinit {
        print("deallocated \(label)")
    }
}

struct ShipView: View {
    let printer = DeallocPrinter("ShipView")
    
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
            self.viewFactory.back()
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
//            .border(Color.red, width: 5)
    }
    
    var headerView: some View {
        HStack {
            HStack(alignment: .top) {
                backButtonView
//                    .border(Color.blue, width: 2)
            }
            .frame(width: 150, height: 50, alignment: .leading)
//            .border(Color.blue, width: 2)
            
            PilotDetailsView(shipPilot: viewModel.shipPilot,
                             displayUpgrades: true,
                             displayHeaders: false)
                .padding(2)
//                .border(Color.green, width: 2)
        }
    }
    
    var bodyContent: some View {
        HStack(alignment: .top) {
            PAKImageView(url: viewModel.shipImageURL,
                         shipViewModel: self.viewModel,
                         label: "ship")
                .frame(width: 350.0, height:500)
                .onTapGesture { self.showCardOverlay.toggle() }
                .overlay( TextOverlay(isShowing: self.$showCardOverlay) )
                .environmentObject(viewModel)
            
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
                }.padding(.top, 20)
//                .border(Color.green, width: 2)

                DialView(temperature: 0,
                     diameter: 400,
                     currentManeuver: $currentManeuver,
                     dial: self.viewModel.shipPilot.ship.dial,
                     displayAngleRanges: false)
                .frame(width: 400.0,height:400)
//                    .border(theme.BORDER_ACTIVE, width: 2)
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
                CustomDivider()
                bodyContent
                CustomDivider()
                footer(showImageOverlay: $showImageOverlay)
    //            footer_New(showImageOverlay: $showImageOverlay)
            }
//            .border(Color.red, width: 2)
            .padding()
            .overlay(imageOverlayView)
            .background(theme.BUTTONBACKGROUND)
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
                
                PAKImageView(url: urlString, shipViewModel: self.viewModel, label: "upgrade")
                    .frame(width: 500.0, height:350)
                    .environmentObject(viewModel)
            })
    }
    
    @State var displayOverlay: Bool = false
    
    var body: some View {
        buildView()
    }
}

// MARK:- Upgrades
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
//                        .environmentObject(self.viewModel)
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
            
            let type = upgrade.sides[0].type.lowercased() + ".json"
            
            let jsonString = loadJSON(fileName: type, directoryPath: "upgrades")
            
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

// MARK:- Images
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

class TestModel: ObservableObject {
    let service: INetworkCacheService
    let id = UUID()
    private var cancellable: AnyCancellable?
    
    init(service: INetworkCacheService = NetworkCacheService(localStore: LocalStore(), remoteStore: RemoteStore()))
    {
        self.service = service
        print("allocated \(self) \(id)")
        print("\(self).init")
    }
    
    deinit {
        print("deallocated \(self) \(id)")
    }
}

extension TestModel {
    func loadImage(url: String) {
        func processCompletion(complete: Subscribers.Completion<Error>) {
            print("\(Date()) \(self).\(#function) received completion event")
            
            switch complete {
            case .failure(let error):
                if let storeError = error as? StoreError {
                    switch storeError {
                    case .localMiss(let url):
                        let message = "No Image in local cache for: \n \(url)"
//                        self.message = message
                        print("\(Date()) \(self).\(#function) \(message)")
                    case .remoteMiss:
                        let message = "No Image found in remote for: \(url)"
//                        self.message = message
                        print("\(Date()) \(self).\(#function) \(message)")
                    }
                }
                
            case .finished:
                print("\(Date()) \(self).\(#function) finished")
            }
        }
        
        func processReceivedValue(value: Data) {
//            self.printLog("received value")
//            
//            if let image = UIImage(data: value) {
//                self.image = image
//                self.message = url
//                self.cache[url] = image
//                self.printLog("cached \(url)")
//            }
        }
        
        self.cancellable = service
            .loadData(url: url)
            .lane("PAK.NetworkCacheViewModel.loadData")
            .receive(on: RunLoop.main)
            .lane("PAK.NetworkCacheViewModel.receive")
            .sink(receiveCompletion: processCompletion,
                  receiveValue: processReceivedValue)
    }
}


struct PAKImageView: View {
    var printer: DeallocPrinter
    let id = UUID()
    let url: String
    @ObservedObject var viewModel : NetworkCacheViewModel
    
//    @ObservedObject var testModel: TestModel
    
    init(url: String, shipViewModel: ShipViewModel, label: String = "") {
        printer = DeallocPrinter("PAKImageView \(id)")
        
        // Images Support
//        let dataStore = CoreDataLocalStore(moc: shipViewModel.moc)
//        let remoteStore = RemoteStore()
//        let service = NetworkCacheService(localStore: dataStore,
//                                          remoteStore: remoteStore,
//                                          label: label)
        
//        self.viewModel = NetworkCacheViewModel(service: service)
//        self.viewModel = NetworkCacheViewModel(moc: shipViewModel.moc)
        self.viewModel = NetworkCacheViewModel(moc: shipViewModel.moc)
//        self.testModel = TestModel(service: service)
        self.url = url
        print("PAKImageView.init(url: \(url)) id = \(id)")
        self.viewModel.loadImage(url: url)
    }
    
                                                            
    /// If the NetworkCacheViewModel adopts INetworkCacheViewModel, I get the following error
    /// Thread 1: EXC_BAD_ACCESS (code=EXC_I386_GPFLT) when referencing self.viewModel.image.
    /// It works if INetworkCacheViewModel is not adopted
    var body: some View {
        Image(uiImage: self.viewModel.image) // Thread Error
            .resizable()
            .onAppear {
                print("\(self.id) PAKImageView Image.onAppear loadImage url: \(self.url)")
            }
    }
}

class PAKImageViewModel: ObservableObject {
    @Published var image: UIImage
    
    let id = UUID()
    
    deinit {
        print("PAKImageViewModel.deinit \(#function).id \(id)")
    }
    
    init() {
        let url = "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_105.png"
        self.image = fetchImageFromURL(urlString: url)
        print("PAKImageViewModel.init = \(id) \(url)")
    }
    
    func loadImage(url: String) {
        self.image = fetchImageFromURL(urlString: url)
        print("PAKImageViewModel.loadImage = \(id) \(url)")
    }
}

// Workaround for https://swiftsenpai.com/swift/define-protocol-with-published-property-wrapper/
extension PAKImageViewModel : INetworkCacheViewModel {
    var imagePublisher: Published<UIImage>.Publisher {
        $image
    }
    
    var imagePublished: Published<UIImage> { _image }
}
