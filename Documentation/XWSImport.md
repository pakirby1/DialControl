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








