#  CountView

![Redux Architecture](https://pakirby1.github.io/images/DialControl-114_WinLoss.png)

We would like to have a `CountView` that is solely responsible for...
- Displaying a button with a label
- Overlaying a banner view on the button with a specified label.

### `CountView`

> Just for Giggles we could use `@ViewBuilder` when building the view layout

```
struct CountView<Content> : View where Content: View {
    let content: () -> (Content)
    
    init(@ViewBuilder _ content: @escaping () -> (Content))
    {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}
```

and in a parent view...

```
struct CountViewContainer: View {
    @StateObject var viewModel = CountViewContainerViewModel()
    
    var body: some View {
        HStack {
            CountView {
                ZStack {
                    VStack {
                        Text("WON")
                        PillButton(label: "\(viewModel.wonCount)", add: { viewModel.increment(.won) }, subtract: { viewModel.decrement(.won) })
                    }
                }
            }
            
            CountView {
                ZStack {
                    VStack {
                        Text("LOST")
                        PillButton(label: "\(viewModel.lostCount)", add: { viewModel.increment(.lost) }, subtract: { viewModel.decrement(.lost) })
                    }
                }
            }
        }
    }
}
```

with view model 
```
class CountViewContainerViewModel : ObservableObject {
    @Published private(set) var wonCount: Count = Count(count: 0)
    @Published private(set) var lostCount: Count = Count(count: 0)
    
    enum CountType {
        case won
        case lost
    }
    
    func increment(_ type: CountType) {
        func limit(_ count: Count) -> Count {
            return count.max
        }
        
        switch(type) {
            case .won :
                wonCount = limit(wonCount)
            case .lost :
                lostCount = limit(lostCount)
        }
    }
    
    func decrement(_ type: CountType) {
        func limit(_ count: Count) -> Count {
            return count.min
        }
        
        switch(type) {
            case .won :
                wonCount = limit(wonCount)
            case .lost :
                lostCount = limit(lostCount)
        }
    }
}
```

and a count structure
```
struct Count {
    let count: Int32
    let limit: Int32 = 20
    
    var min: Count {
        let newCount = count - 1
        
        if (newCount) < 0 {
            return Count(count:0)
        } else {
            return Count(count:newCount)
        }
    }
    
    var max: Count {
        let newCount = count + 1
        
        if (newCount) > limit {
            return Count(count: limit)
        } else {
            return Count(count: newCount)
        }
    }
}
```

we could style a different button:

```
struct PillButton : View {
    let label: String
    let add: () -> Void
    let subtract: () -> Void
    
    var body: some View {
        ZStack {
            Capsule().frame(width: 150, height: 100, alignment: .center)
            
            HStack {
                Button(action: subtract) {
                    Text("-")
                }.border(Color.green, width: 1)
                
                Text(label).foregroundColor(.black).border(Color.red, width: 1)
                
                Button(action: add) {
                    Text("+")
                }.border(Color.green, width: 1)
            }
        }
    }
}
```

### Counter UI
I'd like the views to be consistent across the application so I created a UI prototype using Xd & Vectornator (or any vector editing program like InkScape or Illustrator).

![Counter UI](https://pakirby1.github.io/images/CounterControlNew.png)

The control is made up of...
- Capsule (800 x 200), grey fill, black border
- Line (height 200) black
- 3 100x100 Circles with white fill
- 2 80x80 SFSymbol images with blue fill 
    - minus.circle.fill 
    - plus.circle.fill
- 1 80 x 80 SFSymbol with red fill
    - multiply.circle.fill 

```
ZStack {
    Capsule(...).border(Color.black, 3)
    HStack {
        Button(...) { minus sf symbol }
        Spacer()
        Text(count)
        Spacer()
        Button(...) { plus sf symbol }
        Spacer()
        Line()
        Button(...) { multiply sf symbol }
    }
}
```

