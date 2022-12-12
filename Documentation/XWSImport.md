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






