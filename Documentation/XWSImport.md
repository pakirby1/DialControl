#  XWS Import

## `Redux_SquadXWSImportView`

```swift
self.store.send(.xwsImport(action: .importXWS(self.xws)))
```

This will enlist the store to import the self.xws by calling the `xwsImportReducer.importXWS(xws:)` function.  Eventually the `Squad.serializeJSON(jsonString:callback:)` function.  This function is switched by the `FeatureId.serializeJSON` switch.  This will call the `serializeJSON_New(jsonString:callBack:)` nested function within `Squad.serializeJSON(jsonString:callBack:)`.  This function will call the `serializeJSON(jsonString:)` nested function.

```
Type 'Int' mismatch: Expected to decode Int but found a string/data instead.
codingPath: [_JSONKey(stringValue: "Index 7", intValue: 7), CodingKeys(stringValue: "cost", intValue: nil), CodingKeys(stringValue: "value", intValue: nil)]
```

In the `configuration.json` file we have instances of `"cost": { "value": "???" }`.  The value is expected to be an int but it is a string.

> Do we really care about upgrade `cost`?  Can we ignore it?
> I changed it from `"cost": { "value": "???" }` to `"cost": { "value": 0 }` to fix the error.


## `Usual Suspects`

Imported JSON is represented by a `Squad`.  

The imported XWS

```
{"description":"","faction":"galacticempire","name":"BoyCrew","pilots":[{"id":"darthvader-battleofyavin","name":"darthvader-battleofyavin","points":6,"ship":"tieadvancedx1"},{"id":"maulermithel-battleofyavin","name":"maulermithel-battleofyavin","points":3,"ship":"tielnfighter"},{"id":"sigma7-battleofyavin","name":"sigma7-battleofyavin","points":4,"ship":"tieininterceptor"},{"id":"idenversio","name":"idenversio","points":3,"ship":"tielnfighter","upgrades":{"talent":["elusive"],"cannon":["ioncannon"]}},{"id":"backstabber-battleofyavin","name":"backstabber-battleofyavin","points":4,"ship":"tielnfighter"}],"points":20,"vendor":{"yasb":{"builder":"YASB - X-Wing 2.5","builder_url":"https://yasb.app/","link":"https://yasb.app/?f=Galactic%20Empire&d=v9ZhZ20Z564X125W204W105Y566X127W105Y573X125W113Y218X119WW11WWY565X116W381W105&sn=BoyCrew&obs="}},"version":"10/28/2022"}
```

We really need to focus on the differences between each ship in the squad:

```
{
  "id":"idenversio",
  "name":"idenversio",
  "points":3,
  "ship":"tielnfighter",
  "upgrades":{
    "talent":["elusive"],
    "cannon":["ioncannon"]}
    }
},
{
  "id":"backstabber-battleofyavin",
  "name":"backstabber-battleofyavin",
  "points":4,
  "ship":"tielnfighter"
}
```

A regular ship will have the upgrades node while a quick build squad will have no upgrades node.
A regular ship could also not have an upgrades node.

Both objects are represented as `SquadPilot` objects:

```swift
struct SquadPilot: Codable, Identifiable {
    let id: String
    let points: Int
    let ship: String
    var upgrades: SquadPilotUpgrade? { return _upgrades ?? nil }
    var name: String? { return _name ?? nil }
    
    private var _upgrades: SquadPilotUpgrade?
    private var _name: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case _name = "name"
        case points = "points"
        case ship = "ship"
        case _upgrades = "upgrades"
    }
}
``` 
Notice that both `name` and `upgrades` are optional.


> For our case we would like to transform a `SquadPilot` without upgrades into one with upgrades.

Basically we'd like to translate 

```
{
  "id":"backstabber-battleofyavin",
  "name":"backstabber-battleofyavin",
  "points":4,
  "ship":"tielnfighter"
}
```

into

```
{
  "id":"backstabber-battleofyavin",
  "name":"backstabber-battleofyavin",
  "points":3,
  "ship":"tielnfighter",
  "upgrades":{
    "talent":["crackshot", "disciplined"],
    "modification":["afterburners"]}
    }
}
```

One approach is to transform each `SquadPilot` that contains no upgrades into a `SquadPilot` that does have upgrades only if the ship has a `standardLoadout` entry of upgrades in the ship.

Here's the ship for `backstabber-battleofyavin`

```
{
      "name": "“Backstabber”",
      "caption": "Battle of Yavin",
      "initiative": 5,
      "limited": 1,
      "cost": 4,
      "xws": "backstabber-battleofyavin",
      "ability": "While you perform a primary attack, if a friendly Darth Vader or “Mauler” Mithel is in your [Left Arc] or [Right Arc] at range 0-1, roll 1 additional attack die.",
      "image": "https://infinitearenas.com/xw2/images/quickbuilds/backstabber-battleofyavin.png",
      "artwork": "https://infinitearenas.com/xw2/images/artwork/pilots/backstabber.png",
      "shipStats": [
        { "arc": "Front Arc", "type": "attack", "value": 2 },
        { "type": "agility", "value": 3 },
        { "type": "hull", "value": 4 }
      ],
      "standardLoadout": ["crackshot", "disciplined", "afterburners"],
      "standard": true,
      "extended": true,
      "keywords": ["TIE"],
      "epic": true
    }
```

The pipeline would have the following steps:

- Use the `"id":"backstabber-battleofyavin"` and `"ship":"tielnfighter"` to load the pilot from the ship json.
- Transform the `"standardLoadout": ["crackshot", "disciplined", "afterburners"]` field into
```
"upgrades":{
    "talent":["crackshot", "disciplined"],
    "modification":["afterburners"]}
    }
```
To transform the `standardLoadout`
- Iterate over each upgrade in `standardLoadout`
  - Get the talent for the upgrade from the `UpgradeMap`
    - If the category key doesn't exist in the dictionary, add the category, upgrade key value pair to the dictionary
    - If the category key does exist in the dictionary, append the upgrade to the array keyed by the category.
  - Once the dictionary is created, enumerate the dictionary and add the array for each category to `SquadPilot.upgrades`

## `SquadPilotUpgradesCollection`
A collection that stores upgrades for squad pilots

![Linked View Model Diagram](https://pakirby1.github.io/images/XWSImport-SquadPilotUpgradesCollection.png)

The collection is populated on app start from the upgrades in the `data/upgrades` folder.   Once all the upgrades are populated, we can 

- Obtain all upgrades for a category (`allUpgrades(in:)`)
- Obtain the category for a given upgrade (`category(for:)`)

If we have a list of upgrades, we can obtain a list of tuples of `(category, upgrade)` types:

```swift
func buildUpgradesList(upgrades: [String]) -> [(UpgradeKeyCategory?, String)]
```

we can also build a dictionary of type `[UpgradeKeyCategory: [String]]`

```swift
func buildUpgradesList(upgrades: [String]) -> [UpgradeKeyCategory : [String]] {
        func add(upgrade: String, category: UpgradeKeyCategory) {
            if var upgrades = dict[category] {
                upgrades.append(upgrade)
            } else {
                dict[category] = [upgrade]
            }
        }
        
        var dict: [UpgradeKeyCategory: [String]] = [:]
        
        upgrades.forEach{
            if let category = category(for: $0) {
                add(upgrade: $0, category: category)
            }
        }
        
        return dict
    }
```


```swift
func category(for upgrade: String) -> UpgradeKeyCategory? {
        for key in UpgradeKeyCategory.allCases {
            let upgrades = self[key]
            let upgrade = upgrades.filter{ $0 == upgrade }
            
            if (upgrade.count > 0) {
                return key
            }
        }
        
        return nil
    }
```

If we have a  list of `standardLoadout` upgrades, we can build a dictionary.

```swift
let upgrades = ["crackshot", "disciplined", "afterburners"]
let dict: [UpgradeKeyCategory : [String]] = buildUpgradesList(upgrades)

// Either create a JSON string

// Or add to `SquadPilot.upgrades`

```





