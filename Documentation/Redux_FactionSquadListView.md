#  Refactor Redux_FactionSquadList

Update to use a view model.
![Redux Architecture](https://pakirby1.github.io/images/CacheService-Redux_FactionSquadList.png)

### Redux_FactionSquadListView

- remove store property
- rename displayResetRoundCounter to displayResetRoundCornerConfirmation
- remove `@DataBacked` properties  
- remove faction property
- remove squadDataList
- Add Redux_FactionSquadListViewModel viewModel property
- update methods to reference viewModel.send(...)

```
struct Redux_FactionSquadListView : View {
  @EnvironmentObject var viewFactory: ViewFactory
  @ObservedObject var viewModel: Redux_FactionSquadListViewModel
  @State var displayFavoritesOnly: Bool
  @State var displayResetRoundCounterConfirmation: Bool
  let printer: DeallocPrinter
  var body: some View
  init(faction: String)
  private func cancelAction(title: String, callback: @escaping () -> Void) -> () -> Void  
}

extension Redux_FactionSquadListView {
  private func deleteSquad(squadData: SquadData)
  private func updateSquad(squadData: SquadData)
  private func refreshSquadsList()
  private func updateFavorites(showFavoritesOnly: Bool)
}
```

- How do we get a view model?
  - it's passed in from the `ViewFactory` when the view is created.
    - it's created in an `init()` call.
  - it's created in `.onAppear()` call.

```
  func Redux_buildView(type: ViewType) -> AnyView {
        func buildShipView(shipPilot: ShipPilot, squad: Squad) -> AnyView {
            let viewModel = Redux_ShipViewModel(moc: self.moc,
                                          shipPilot: shipPilot,
                                          squad: squad,
                                          pilotStateService: self.diContainer.pilotStateService,
                                          store: store)
            
            return AnyView(Redux_ShipView(viewModel: viewModel)
                .environmentObject(self)
            )
        }
```

### IViewModel
```
protocol IViewModel {
  associatedtype ViewModelAction
  associatedtype ViewProperties
  var viewProperties: ViewProperties
  func send(action: ViewModelAction)
}
```
### Redux_FactionSquadListViewModel
```
class Redux_FactionSquadListViewModel<Store> : ObservableObject, IViewModel {
  var store: Store
  @Published private(set) var viewProperties: Redux_FactionSquadListViewProperties
  func send(_ action: Redux_FactionSquadListViewModelAction)
}
```
### Redux_FactionSquadListViewModelAction
```
enum Redux_FactionSquadListViewModelAction : CustomStringConvertible {
  case deleteSquad(SquadData)
  case updateSquad(SquadData)
  case updateFavorites(Bool)
  case refreshSquadsList
}
```
### Redux_FactionSquadListViewProperties
```
struct Redux_FactionSquadListViewProperties {
  var squadDataList : [SquadData]
  let faction : String
}
```


