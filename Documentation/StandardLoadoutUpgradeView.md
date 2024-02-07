# Standard Loadout Upgrade View

The upgrade view for a standard loadout should look like:

![Blank Signature Upgrade](https://pakirby1.github.io/images/BlankSignatureUpgrade.png)

- Which is represented by a Swift UI view
- The body consists of Text and Symbol segments

![Blank Signature Segments](https://pakirby1.github.io/images/BlankSignature_Segments.png)

- The upgrade text is taken from the Blank Signature sides.ability node in upgrades/sensor.json
- `findDelimitedSubstrings(input:) -> [String]` returns an array of the substrings.  This function is a member of UpgradeTextView class (Views/UpgradeView.swift)

|Index|Value|
|-|-|
|0|"While defending, if you are "|
|1|"[Charge]"|
|2|" to change 1 "|
|3|"[Focus]"|
|4|" result to an "|
|5|"[Evade]"|
|6|" result."|

- `createSubstringArray(input:) -> [SubstringType]` converts the string array into a `[SubstringType]` array

|Index|Value|
|-|-|
|0|SubstringType.Text("While defending, if you are ")|
|1|SubstringType.Symbol("[Charge]")|
more...

- Merge any contiguous substrings, if needed.
> For the cases where the string is " perform a [1 [Straight]] " in the sides.ability node of the upgrade.

`mergeSameSubstringTypes(_ input: [SubstringType]) -> [SubstringType]`

- Build a SwiftUI view from the `[SubstringType]` array.

```swift
func buildViews(_ input: [SubstringType]) -> some View {
    func buildView(_ type: SubstringType) -> Text {
        switch(type) {
            case .text(let val):
            return Text(val)
        case .symbol(let val):
            return Text(getSymbol(val))
                .font(.custom("xwing-miniatures", size: 18))
        }
    }

    return VStack(alignment: .center) {
        input.reduce(Text(""), { $0 + buildView($1) } )
    }
}
```

> `getSymbol(val:)` returns a character from the xwing-miniatures font that corresponds to the associated type of the symbol in the `[SubstringType]` array. (`SubstringType.Symbol("[Charge]")` corresponds to the `g` character in the xwing-miniatures font)

```mermaid
flowchart TD
    A[Redux_ShipView.body.content] --> B[Redux_ShipView.imageOverlayView]
    B --> C[Redux_ShipView.imageOverlayView.upgradeImageOverlay]
    C --> D[Redux_ShipView.imageOverlayView.upgradeImageOverlay.upgradeCardImage]
    D --> E[UpgradeCardFlipView]
    D -->|selectedUpgrade.upgrade.isStandardLoadoutUpgrade| F[UpgradeTextView]
```

```mermaid
classDiagram

class Redux_ShipView {
    var viewModel: Redux_ShipViewModel
    "@State var showImageOverlay: Bool = false"
    "@State var selectedUpgrade: UpgradeView.UpgradeViewModel? = nil"
}

class UpgradesView {
    let upgrades: [Upgrade]
    @Binding var showImageOverlay: Bool
    "@Binding var selectedUpgrade: UpgradeView.UpgradeViewModel?"
}
```

The `UpgradesView` is built, passing in the `[Upgrades]` and any `@State` variables which are used as `@Binding` variables in `UpgradesView`.

`Redux_ShipView.body.content.footer`:
```swift
var footer: some View {
    UpgradesView(upgrades: viewModel.shipPilot.upgrades,
                    showImageOverlay: $showImageOverlay,
                    imageOverlayUrl: $imageOverlayUrl,
                    imageOverlayUrlBack: $imageOverlayUrlBack,
                    selectedUpgrade: $selectedUpgrade)
        .environmentObject(viewModel)
}
```
UpgradesView.swift:
```swift
ForEach(upgrades) {
    UpgradeView(viewModel: UpgradeView.UpgradeViewModel(upgrade: $0))
    { upgradeViewModel in
        self.showImageOverlay = true
        self.imageOverlayUrl = upgradeViewModel.imageUrl
        self.imageOverlayUrlBack = upgradeViewModel.imageUrlBack
        self.selectedUpgrade = upgradeViewModel
    }
    .environmentObject(viewModel)
}
```
The closure passed into `UpgradeView` is executed when an upgrade button is tapped.  

- The `showImageOverlay` is set to true when the upgrade button is tapped
- The `selectedUpgrade` is set when the upgrade button in the footer of the ship view is tapped.  It is set to the `UpgradeView.UpgradeViewModel` which is initialized from the  `Upgrade`

The `body` of `Redux_ShipView` adds the `imageOverlayView` as an overlay:

`Redux_ShipView.body`:
```swift
return VStack(alignment: .leading) {
                headerView
                bodyContent
                footer
            }
            .padding()
            .overlay(imageOverlayView)
```

The `showImageOverlay` toggles whether the `upgradeImageOverlay` or the `defaultView` is displayed:
`Redux_ShipView.imageOverlayView`:
```swift
if (self.showImageOverlay == true) {
    return AnyView(upgradeImageOverlay)
} else {
    return defaultView
}
```

The `upgradeImageOverlay` references the `upgradeCardImage` which displays the `UpgradeCardFlipView`:
```swift
if (self.imageOverlayUrlBack != "") {
    guard let selectedUpgrade = self.selectedUpgrade else { return emptyView }
    
    guard let upgradeState = getUpgradeStateData(upgrade: selectedUpgrade.upgrade) else { return emptyView }
    
    // if not standard loadout upgrade
    ret =
        UpgradeCardFlipView(
            side: (upgradeState.selected_side == 0) ? false : true,
            frontUrl: self.imageOverlayUrl,
            backUrl: self.imageOverlayUrlBack,
            viewModel: self.viewModel) { side in
                self.viewModel.update(
                    type: PilotStatePropertyType.selectedSide(upgradeState,
                                                                side), active: -1, inactive: -1
                )
        }.eraseToAnyView()
    
    // if standard loadout upgrade
    // ret = UpgradeTextView
}
```

```mermaid
flowchart TD
    A[Redux_ShipView.body.content.footer] -->|Upgrades, selectedUpgrade| B[UpgradesView]
    B -->|UpgradeViewModel| C[UpgradeView]
    C -->|selectedUpgrade, showImageOverlay| D[Redux_ShipView.imageOverlayView]
    D --> E[upgradeImageOverlay]
    E --> F[UpgradeCardFlipView]
    E -->|selectedUpgrade.isStandardLoadout| G[UpgradeTextView]
```
Tasks
- Add `var isStandardLoadout: Bool = false` to `Upgrade`
- Set `isStandardLoadout` when building the `Redux_ShipViewModel.shipPilot.upgrades` that is injected into `Redux_ShipView` from `ContentView.Redux_buildView()`.  which is triggered from tapping a ship card on the squad view.


ContentView.swift
```swift
func Redux_buildView(type: ViewType) -> AnyView {
    case .shipViewNew(let shipPilot, let squad):
                return buildShipView(shipPilot: shipPilot, squad: squad)
}
```
```swift
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

```mermaid
flowchart TD
    A[Ship card tap on SquadView] -->|"ViewType.shipViewNew(shipPilot,squad)"| B["buildShipView(shipPilot, squad)"]
    B -->|"shipPilot, squad"| C[Redux_ShipViewModel]
    C -->|"viewModel"| D[Redux_ShipView]
```

```mermaid
flowchart TD
    Y["Redux_SquadViewNewViewModel.loadShips(squad, squadData)"] --> W["squadReducer.getShips(squad,data)"]
    W -->|squad, SquadData| C["SquadService.getShips"]
    Z["Redux_SquadView.loadShips"] --> A
    V["Redux_SquadView.content.onAppear"] --> Z
    A["factionReducer(.getShips(SquadData))"] -->|SquadData| C["SquadService.getShips"]
    B["squadReducer(.flipDialFix)"] -->|squad, SquadData| C["SquadService.getShips"]
    C -->|squad, squadPilot, pilotState| D["CacheService.getShip"]
    D -->|squad, squadPilot, pilotState| E["CacheService.getShipV1"]
    E -->|inout Ship| F["CacheService.getShipV1.getPilot"]
    F --> G["CacheService.getShipV1.getPilot.getUpgradesFromCache"]
    G --> H["CacheService.getShipV1.getPilot.getUpgradesFromCache.getUpgrade(key:)"]
    H --> I["UpgradeUtility.getUpgrades(upgradeCategory)"]
```

# Upgrade text header view
The header of the upgrade text view consists of
- upgrade category symbol
- upgrade title
- chages, if any

![Blank Signature Upgrade](https://pakirby1.github.io/images/BlankSignatureUpgrade.png)

We can represent the header as a view:

```mermaid
classDiagram
    class UpgradeTextHeaderView {
        var chargeView: View
        let category: UpgradeUtility.UpgradeCategories
        let title: String
        let chargeSymbol: String = "g"
        let chargeValue: Int
        let isRecurring: Bool
        var body: some View
        func buildSymbol() -> some View
    }

    class ChargeView {
        let symbol: String = "g"
        let value: Int
        let isRecurring: Bool
        var body: some View
        var chargeSymbol : some View
        var recurringSymbol : some View

        func buildSymbol() -> some View
    }

    UpgradeTextHeaderView --> ChargeView : chargeSymbol, chargeValue, isRecurring
```

# Loading Images from an app Bundle
https://stackoverflow.com/questions/66996051/issue-with-image-not-found-in-bundle-for-app

Instead of loading the images from a remote web server, we'd like to load the images from the app bundle. 

```mermaid
classDiagram
    class IRemoteStore {
        func loadData(url: String) -> Future<RemoteObject, Error>
    }

    class RemoteStore {
        func loadData(url: String) -> Future<Data, Error>
    }

    IRemoteStore <|-- RemoteStore
```

The `RemoteStore` fetches images from a web server, but we also need to support fetching images from an app bundle, so we define a class called `RemoteWebStore` and `RemoteAppBundleStore`.
> Here `Remote` just differentiates the download process from the cache (`Local`)

```mermaid
classDiagram
    class IRemoteStore {
        func loadData(url: String) -> Future<RemoteObject, Error>
    }

    class RemoteWebStore {
        func loadData(url: String) -> Future<Data, Error>
    }

    class AppBundleStore {
        func loadData(url: String) -> Future<Data, Error>
    }

    IRemoteStore <|-- RemoteWebStore
    IRemoteStore <|-- AppBundleStore
```

The call hierarchy:

```mermaid
flowchart TD
    UpgradeCardFlipView -->|url| ImageView
    ShipView.upgradeCardImage -->|url| ImageView
    ShipView.bodyContent -->|url| ImageView
    Redux_ShipView.imageOverlayView.upgradeCardImage -->|url| ImageView
    ImageView -->|url| NetworkCacheViewModel.loadImage
    NetworkCacheViewModel.loadImage -->|url| NetworkCacheService.loadData

```

