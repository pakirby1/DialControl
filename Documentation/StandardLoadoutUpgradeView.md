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
