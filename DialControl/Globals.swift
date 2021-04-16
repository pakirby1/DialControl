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

public extension View {
    func myAlert(isPresented: Binding<Bool>,
               title: String,
               message: String? = nil,
               dismissButton: Alert.Button? = nil) -> some View
    {

        alert(isPresented: isPresented) {
            Alert(title: Text(title),
                  message: {
                    if let message = message { return Text(message) }
                    else { return nil } }(),
                  dismissButton: dismissButton)
        }
    }
}

/*
 .alert(isPresented: $displayDeleteAllConfirmation) {
     Alert(title: Text("Delete"),
           message: Text("All Squads?"),
         primaryButton: Alert.Button.default(Text("Delete"), action: {
             _ = self.viewModel.squadDataList.map { self.viewModel.deleteSquad(squadData: $0) }
         }),
         secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {
             print("Cancelled Delete")
         })
     )
 }
 */
struct LongPressAlertModifier: ViewModifier {
//    @State var showAlert = false
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        content
//            .onLongPressGesture {
//                self.showAlert = true
//            }
            .alert(isPresented: $isPresented) {
                Alert(title: Text("Alert"), message: Text(message), dismissButton: .default(Text("OK!")))
            }
    }
}

extension View {
    func addLongPressAlert(_ isPresented: Binding<Bool>, _ message: String) -> some View {
        self.modifier(LongPressAlertModifier(isPresented: isPresented, message: message))
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

extension View {
    func addAlert(_ showAlert: Binding<Bool>, properties: AlertModifier.Properties) -> some View {
        self.modifier(AlertModifier(showAlert: showAlert,
                                    properties: properties))
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

// MARK:- DeallocPrinter to determine when structs are deallocated
protocol IDeallocPrinter {
    var printer: DeallocPrinter { get set }
    var id: UUID { get }
}

class DeallocPrinter {
    let label: String
    let id = UUID()
    
    init(_ label: String) {
        self.label = label
        print("\(Date()) allocated \(id) \(label)")
//        DispatchQueue.global(qos: .)
    }
    
    deinit {
        print("\(Date()) deallocated \(id) \(label)")
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

func getJSONFor(ship: String, faction: String) -> String {
    var ret = ""
    
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
                    print("jsonData: \(shipJSON)")
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
