//
//  Redux_FactionSquadCard.swift
//  DialControl
//
//  Created by Phil Kirby on 4/24/22.
//  Copyright © 2022 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class Redux_FactionSquadCardViewModel : ObservableObject {
    private var damagedPointsPublisher : AnyPublisher<Int, Never> {
        self.store.$state
            .map{ state -> [SquadData] in
                return state.faction.squadDataList
            }
            .map { squadDataList -> Int in
                if let targetSquad = squadDataList.first(where:{ $0.id == self.squadData.id})
                {
                    let damagedPoints = targetSquad.damagedPoints
                    return damagedPoints
                }
                
                return 0
            }
            .print("myState Redux_FactionSquadCardViewModel.damagedPointsPublisher")
            .eraseToAnyPublisher()
    }
    
    let store : MyAppStore
    @Published var damagedPoints : Int = 0
    private var cancellables = Set<AnyCancellable>()
    let squadData: SquadData
    
    init(squadData: SquadData, store: MyAppStore) {
        self.squadData = squadData
        self.store = store
        self.damagedPointsPublisher
            .sink{
                self.damagedPoints = $0
            }
            .store(in: &cancellables)
    }
    
    let points: Int = 150
    let theme: Theme = WestworldUITheme()
    let symbolSize: CGFloat = 36.0
    
    var buttonBackground: Color {
        theme.BUTTONBACKGROUND
    }
    
    var textForeground: Color {
        theme.TEXT_FOREGROUND
    }
    
    var border: Color {
        theme.BORDER_INACTIVE
    }
}

struct Redux_FactionSquadCard: View  {
    @EnvironmentObject var viewFactory: ViewFactory
    @EnvironmentObject var store: MyAppStore
    let viewModel: Redux_FactionSquadCardViewModel
    
    @State var displayDeleteConfirmation: Bool = false
    @State var refreshView: Bool = false
//    @State var damagedPointsState: Int = 0
    
    let printer: DeallocPrinter
    
    let deleteCallback: (SquadData) -> ()
    let updateCallback: (SquadData) -> ()
    let squadData: SquadData

    init(squadData: SquadData,
         store: MyAppStore,
         deleteCallback: @escaping (SquadData) -> (),
         updateCallback: @escaping (SquadData) -> ())
    {
        self.deleteCallback = deleteCallback
        self.updateCallback = updateCallback
        self.squadData = squadData
        self.viewModel = Redux_FactionSquadCardViewModel(squadData: squadData, store: store)
        self.printer = DeallocPrinter("damagedPoints FactionSquadCard")
    }
    
    func favoriteTapped() {
        measure(name:"favoriteTapped") {
            logMessage("damagedPoints Redux_FactionSquadCardViewModel.favoriteTapped()")
            squadData.favorite.toggle()
            updateCallback(squadData)
        }
    }
    
    func deleteSquad() {
        deleteCallback(squadData)
    }
    
    var squad: Squad {
        squadData.squad
    }
    
    var background: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(viewModel.buttonBackground)
            .frame(width: 800, height: 80)
            .overlay(border)
    }
    
    var pointsView: some View {
        Text("\(squad.points ?? 0)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    var damagedPointsView: some View {
        logMessage("myState Redux_FactionSquadCard.damagedPointsView")
        
        return Text("\(squadData.victoryPoints)")
            .font(.title)
            .foregroundColor(viewModel.textForeground)
            .padding()
            .background(Color.red)
            .clipShape(Circle())
    }
    
    /*
     For the common case of text-only labels, you can use the convenience initializer that takes a title string (or localized string key) as its first parameter, instead of a trailing closure:

     Button("Sign In", action: signIn)
     */
    var vendorView: some View {
        Button("\(self.squad.vendor?.description ?? "")") {
            UIApplication.shared.open(URL(string: self.squad.vendor?.link ?? "")!)
        }
    }
    
    var favoriteView: some View {
        Button(action: {
            logMessage("damagedPoints favoriteTapped")
            self.favoriteTapped()
        }) {
            Image(systemName: self.squadData.favorite ? "star.fill" :
            "star")
                .font(.title)
                .foregroundColor(Color.yellow)
        }
    }
    
    var factionSymbol: some View {
        let faction: Faction? = Faction.buildFaction(jsonFaction: squad.faction)
        let characterCode = faction?.characterCode
        
        return Button(action: {
            UIApplication.shared.open(URL(string: self.squad.vendor?.link ?? "")!)
        }) {
            Text(characterCode ?? "")
                .font(.custom("xwing-miniatures", size: self.viewModel.symbolSize))
        }
    }
    
    var nameView: some View {
        HStack {
            Text(squad.name ?? "Unnamed")
                .font(.title)
                .foregroundColor(viewModel.textForeground)
        }
    }
    
    var border: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(viewModel.border, lineWidth: 3)
    }
    
    var deleteButton: some View {
        Button(action: {
            self.displayDeleteConfirmation = true
        }) {
            Image(systemName: "trash.fill")
                .font(.title)
                .foregroundColor(Color.white)
        }.alert(isPresented: $displayDeleteConfirmation) {
            Alert(title: Text("Delete"),
                  message: Text("\(self.squadData.name ?? "Squad")"),
                primaryButton: Alert.Button.default(Text("Delete"), action: deleteAlertAction),
                secondaryButton: Alert.Button.cancel(Text("Cancel"), action: cancelAlertAction)
            )
        }
    }
    
    @ViewBuilder
    private var firstPlayerView: some View {
        if self.squadData.firstPlayer == true {
            firstPlayerSymbol
        } else {
            EmptyView()
        }
    }
    
    private var victoryPointsView: some View {
        HStack {
            IndicatorView(label: "\(3)",
                bgColor: Color.red,
                fgColor: Color.white)
            
            Image(uiImage: UIImage(named: "VictoryYellow") ?? UIImage())
                .resizable()
                .frame(width: 40, height: 55, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }
    }
    
    var squadButton: some View {
        Button(action: {
            self.viewFactory.viewType = .squadViewPAK(self.squad, self.squadData)
        }) {
            ZStack {
                background
                factionSymbol.offset(x: -370, y: 0)
                pointsView.offset(x: -310, y: 0)
                damagedPointsView.offset(x: -230, y: 0)
                nameView
                firstPlayerView.offset(x: 260, y: 0)
                favoriteView.offset(x: 300, y: 0)
                deleteButton.offset(x: 350, y: 0)
            }
        }
    }
    
    var deleteAlertAction: () -> Void {
        get {
            func old() {
                self.deleteSquad()
            }
            
            func new() {
                if FeaturesManager.shared.isFeatureEnabled(.Redux_FactionSquadList)
                {
                    old()
                }
                else {
                    self.store.send(.faction(action: .deleteSquad(self.squadData)))
                }
                
            }
            
            return {
                if FeaturesManager.shared.isFeatureEnabled(.MyRedux)
                {
                    new()
                } else {
                    old()
                }
            }
        }
    }
    
    var cancelAlertAction: () -> Void {
        get {
            return self.cancelAction(title: "Delete") {
                self.displayDeleteConfirmation = false
            }
        }
    }
    
    func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void {
        return {
            print("Cancelled \(title)")
            callback()
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            squadButton
            Spacer()
        }
        .onAppear() {
            // The view body has been previously executed so the
            // view body needs to be recreated after onAppear
            // This can be done by updating an @State property, or
            // observing an @Published property.
            global_os_log("Redux_FactionSquadCard.body.onAppear() for \(String(describing: self.squadData.squad.name))")
            
            // Have to call in .onAppear because the @EnvironmentObject store
            // is not available until AFTER init() is called
            
            // inject the AppStore into the view model here since
            // @EnvironmentObject isn't accessible in the init()
        }
    }
}
