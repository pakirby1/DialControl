//
//  Globals.swift
//  DialControl
//
//  Created by Phil Kirby on 7/8/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import os
import CoreData

func global_os_log(_ message: String = "", _ value: String = "") {
    os.os_log("[%@] value: %@", message, value)
}

func global_os_log(_ message: String = "", _ valueFactory: () -> String) {
    os.os_log("[%@] value: %@", message, valueFactory())
}

extension View {
    func debugPrint(_ message: String) -> some View {
        #if DEBUG
        global_os_log(message)
        #endif
        return self
    }
}

struct LogView : View {
    var body: some View {
        ScrollView {
            ForEach(0..<100) { i in
                GeometryReader { geo in
                    Text("Row \(i)")
                        .debugPrint("Row \(i): \(geo.frame(in: .global))")
                }
                .frame(height: 50)
            }
        }
    }
}

extension Publisher {
    /// Logs to the console
    func os_log(message: String = "") -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { value in
            os.os_log("[%@] value: %@", message, String(describing: value))
        })
    }
    
    /// Logs to the console
    /// - Parameters:
    ///   - message: identifier
    ///   - valueFactory: builds a string vs using the default type.description.
    /// - Returns: new publisher
    func os_log(message: String = "", valueFactory: @escaping (Self.Output) -> String ) -> Publishers.HandleEvents<Self>
    {
        handleEvents(receiveOutput: { value in
            os.os_log("[%@] value: %@", message, valueFactory(value))
        })
    }
}

// Domain specific Publisher extensions
extension Publisher where Output == [ShipPilot] {
    func logShips(squadName: String) -> Publishers.HandleEvents<Self> {
        return self.os_log(message: "Store.send MySquadAction.getShips") { shipPilots in
            "\(String(describing: squadName)) : \(shipPilots.shortDescription)"
        }
    }
}
    
// MARK :-
/// property wrapper for data stored in UserDefaults
/// @UserDefaultsBacked<Int>(key: "currentRound") var currentRound = 0
/// @DataBacked(key: "currentRound", storage: UserDefaultsStorage()) var currentRoud : Int = 0
/// @DataBacked(key: "test", storage: CoreDataStorage()) var test: SquadData = SquadData.init()
/// @CoreDataBacked<GameData> var gameData? = nil
@propertyWrapper struct UserDefaultsBacked<Value> {
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }

    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults

    init(wrappedValue defaultValue: Value,
         key: String,
         storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
}

@propertyWrapper
struct Input<Value> {
    var wrappedValue: Value {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject: CurrentValueSubject<Value, Never>

    init(wrappedValue: Value) {
        subject = CurrentValueSubject(wrappedValue)
    }
}

/// @DataBacked(key: "roundCount", storage: CoreDataStorage(self.moc)) var roundCount: Int
@propertyWrapper struct DataBacked<Storage: IDataStorage, Value> where Storage.Value == Value
{
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key)
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue: newValue, forKey: key)
        }
    }

    private let key: String
    private let defaultValue: Value
    private let storage: Storage

    init(wrappedValue defaultValue: Value,
         key: String,
         storage: Storage)
    {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
}

struct UserDefaultsStorage<T> : IDataStorage {
    func value(forKey: String) -> T? {
        return backed.value(forKey: forKey) as? T
    }
    
    func setValue(newValue: T, forKey: String) {
        backed.setValue(newValue, forKey: forKey)
    }
    
    let backed = UserDefaults()
}

class CoreDataStorage<T:NSManagedObject> : IDataStorage {
    
    func value(forKey: String) -> T? {
        return nil
    }
    
    func setValue(newValue: T, forKey: String) {
        
    }
}

struct CombineStorage<T> : IDataStorage {
    private let subject: CurrentValueSubject<T, Never>
    
    func value(forKey: String) -> T? {
        return subject.value
    }
    
    func setValue(newValue: T, forKey: String) {
        subject.value = newValue
    }
    
    init(initialValue: T) {
        self.subject = CurrentValueSubject(initialValue)
    }
}

protocol IDataStorage {
    associatedtype Value
    
    func value(forKey: String) -> Value?
    func setValue(newValue: Value, forKey: String)
}

struct LongPressAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(title: Text("Alert"), message: Text(message), dismissButton: .default(Text("OK!")))
            }
    }
}

struct AlertModifier: ViewModifier {
    struct Properties {
        let message: String
        let title: String
        let primaryButtonLabel: String
        let primaryButtonAction: () -> Void
        let secondaryButtonLabel: String
        let secondaryButtonAction: () -> Void
    }
    
    @Binding var showAlert: Bool
    let properties: Properties
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $showAlert) {
                Alert(title: Text(properties.title),
                      message: Text(properties.message),
                      primaryButton: Alert.Button.default(Text(properties.primaryButtonLabel),
                                                          action: properties.primaryButtonAction),
                      secondaryButton: Alert.Button.default(Text(properties.secondaryButtonLabel),
                                                            action: properties.secondaryButtonAction)
                    )
            }
    }
}

func logMessage(_ message: String) {
    print("\(Date()) \(message)")
}

var settingsSymbol: some View {
    return Image(systemName: "gear")
        .font(.system(size: 30.0, weight: .bold))
        .foregroundColor(Color.white)
        .eraseToAnyView()
}

var firstPlayerSymbol: some View {
    Image(uiImage: UIImage(named: "FirstPlayer") ?? UIImage())
}

var shipLookupTable: [String:Array<PilotFileUrl>] = [:]

struct ImageUrlTemplates {
    static func buildPilotUrl(xws: String) -> String {
        return "https://pakirby1.github.io/images/XWing/pilots/\(xws).png"
    }
    
    static func buildPilotUpgradeFront(xws: String) -> String {
        return "https://pakirby1.github.io/images/XWing/upgrades/\(xws).png"
    }
    
    static func buildPilotUpgradeBack(xws: String) -> String {
        return "https://pakirby1.github.io/images/XWing/upgrades/\(xws)-sideb.png"
    }
}

func version() -> String {
    let dictionary = Bundle.main.infoDictionary!
    let version = dictionary["CFBundleShortVersionString"] as! String
    let build = dictionary["CFBundleVersion"] as! String
    return "\(version) build \(build)"
}

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

// MARK:- Synchronous image fetch
func fetchImageFromURL(urlString: String) -> UIImage {
    var image: UIImage? = nil
    
    let url = URL(string: urlString)!

    // Synchronous download using Data & String
    do {
        let data = try Data(contentsOf: url)
        image = UIImage(data: data)
    }
    catch {
        print(error.localizedDescription)
    }
    
    return image!
}

// MARK:- DeallocPrinter to determine when structs are deallocated
protocol IDeallocPrinter {
    var printer: DeallocPrinter { get set }
    var id: UUID { get }
}

class DeallocPrinter {
    let id: UUID
    let label: String
    
    init(_ label: String) {
        self.label = label
        self.id = UUID()
        print("allocated \(id) \(label)")
        global_os_log("allocated \(id) \(label)")
    }
    
    deinit {
        print("deallocated \(id) \(label)")
        global_os_log("deallocated \(id) \(label)")
    }
}

extension DeallocPrinter : CustomStringConvertible {
    var description: String {
        " \(id) \(label) "
    }
}

// MARK:- Images
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

struct URLImageView<T: View>: View {
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
    }
    
    init(url: URL, view: T? = nil) {
        self.imageFetcher = ImageFetcher(url: url)
        self.placeholder = view
    }
}

struct NavigationContentView : View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello World")
                NavigationLink(destination:Text("Hello")) {
                    Text("Do Something")
                }
            }
        }
    }
}

class TimeCounter: ObservableObject {
    @Published var time = 0

    lazy var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in self.time += 1
        print("TimeCounter.time: \(self.time)")
    }
    
    init() {
        timer.fire()
    }
}

public struct CustomStyle : TextFieldStyle {
  public func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(7)
      .background(
        RoundedRectangle(cornerRadius: 15)
          .strokeBorder(Color.black, lineWidth: 5)
    )
  }
}

// MARK :- JSON that everyone eventually calls
func getJSONFor(ship: String, faction: String) -> String {
    var ret = ""
    print("getJSONFor ship: \(ship) faction: \(faction)")
    
    if let pilotFileUrls = shipLookupTable[ship] {
        let matchingFaction = pilotFileUrls.filter({ $0.faction == faction })
        
        if matchingFaction.count == 1 {
            let pilotFileUrl = matchingFaction[0]
            print("pilotFileUrl: \(pilotFileUrl)")
            
            if let path = Bundle.main.path(forResource: pilotFileUrl.fileName,
                                           ofType: "",
                                           inDirectory: pilotFileUrl.directoryPath)
            {
                print("path: \(path)")
                
                do {
                    ret = try String(contentsOfFile: path)
                    print("jsonData: \(ret)")
                } catch {
                    print("error reading from \(path)")
                }
            }
        } else {
            print("No matching json for shipName: \(ship)\nfaction: \(faction)\n")
        }
    }
    
    return ret
}

@discardableResult
func measure<A>(_ feature: String = "", name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    global_os_log("\(feature) Time: \(name) - \(timeElapsed)")
    return result
}

@discardableResult
func measureThrows<A>(_ feature: String = "", name: String = "", _ block: () throws -> A) throws -> A {
    do {
        let startTime = CACurrentMediaTime()
        let result = try block()
        let timeElapsed = CACurrentMediaTime() - startTime
        print("\(feature) Time: \(name) - \(timeElapsed)")
        return result
    } catch {
        throw SquadServiceProtocolError.saveSquadError(error.localizedDescription)
    }
}

func ForEachWithIndex<Data: RandomAccessCollection, Content: View>(
    _ data: Data,
    @ViewBuilder content: @escaping (Data.Index, Data.Element) -> Content)
-> some View where Data.Element: Identifiable, Data.Element: Hashable
{
    ForEach(Array(zip(data.indices, data)), id:\.1) { index, element in
        content(index, element)
    }
}

let shipJSON = """
{
  "name": "TIE/in Interceptor",
  "xws": "tieininterceptor",
  "ffg": 41,
  "size": "Small",
  "dial": [
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
    "3PR"
  ],
  "dialCodes": [
    "TI"
  ],
  "faction": "Galactic Empire",
  "stats": [
    { "arc": "Front Arc", "type": "attack", "value": 3 },
    { "type": "agility", "value": 3 },
    { "type": "hull", "value": 3 }
  ],
  "actions": [
    { "difficulty": "White", "type": "Focus" },
    { "difficulty": "White", "type": "Evade" },
    { "difficulty": "White", "type": "Barrel Roll" },
    { "difficulty": "White", "type": "Boost" }
  ],
  "icon": "https://sb-cdn.fantasyflightgames.com/ship_types/I_TIEInterceptor.png",
  "pilots": [
    {
      "name": "Alpha Squadron Pilot",
      "initiative": 1,
      "limited": 0,
      "cost": 31,
      "xws": "alphasquadronpilot",
      "text": "Sienar Fleet Systems designed the TIE interceptor with four wing-mounted laser cannons, a dramatic increase in firepower over its predecessors.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_106.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_106.jpg",
      "ffg": 106,
      "hyperspace": false
    },
    {
      "name": "Saber Squadron Ace",
      "initiative": 4,
      "limited": 0,
      "cost": 36,
      "xws": "sabersquadronace",
      "text": "Led by Baron Soontir Fel, the pilots of Saber Squadron are among the Empire's best. Their TIE interceptors are marked with red stripes to designate pilots with at least ten confirmed kills.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_105.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_105.jpg",
      "ffg": 105,
      "hyperspace": false
    },
    {
      "name": "Soontir Fel",
      "caption": "Ace of Legend",
      "initiative": 6,
      "limited": 1,
      "cost": 53,
      "xws": "soontirfel",
      "ability": "At the start of the Engagement Phase, if there is an enemy ship in your [Bullseye Arc], gain 1 focus token.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_103.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_103.jpg",
      "ffg": 103,
      "hyperspace": false
    },
    {
      "name": "Turr Phennir",
      "caption": "Ambitious Ace",
      "initiative": 4,
      "limited": 1,
      "cost": 42,
      "xws": "turrphennir",
      "ability": "After you perform an attack, you may perform a [Barrel Roll] or [Boost] action, even if you are stressed.",
      "image": "https://sb-cdn.fantasyflightgames.com/card_images/Card_Pilot_104.png",
      "shipAbility": {
        "name": "Autothrusters",
        "text": "After you perform an action, you may perform a red [Barrel Roll] or red [Boost] action."
      },
      "slots": ["Talent", "Modification", "Modification"],
      "artwork": "https://sb-cdn.fantasyflightgames.com/card_art/Card_art_XW_P_104.jpg",
      "ffg": 104,
      "hyperspace": false
    }
  ]
}
"""
