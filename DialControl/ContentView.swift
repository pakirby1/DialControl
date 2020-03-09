//
//  ContentView.swift
//  DialControl
//
//  Created by Phil Kirby on 2/15/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import SwiftUI
import Combine
import TimelaneCombine

class Test : ObservableObject {
    @Published var temperature: CGFloat = 0.0
}

struct ContentView: View {
    let test = Test()
    
    var body: some View {
        let binding = Binding<CGFloat>(
            get: { self.test.temperature },
            set: { self.test.temperature = $0} )

        return DialView(temperature: 0,
                               diameter: 500)
    }
}

struct DialControl: View {
    var segmentCount: UInt = 16
    var selectedSegments: [UInt] = [6]
    var width: CGFloat
    var height: CGFloat
    var innerRatio = (7 / 8)
    
    var body: some View {
        RotatingCircle(width: width, height: height)
    }
}

struct RotatingCircle: View {
    @State var angle = Angle(degrees: 0.0)
    var width: CGFloat
    var height: CGFloat
    @State var xLocation: CGFloat = 0
    @State var yLocation: CGFloat = 0
    @State private var currentAmount: Angle = .degrees(0)
    @State private var finalAmount: Angle = .degrees(0)
    
    var rotation: some Gesture {
        RotationGesture()
            .onChanged { angle in
                self.angle = angle
            }
    }
    
    var drag: some Gesture {
       DragGesture().onChanged() { value in
        self.xLocation = value.location.x
        self.yLocation = value.location.y
        
//           let x: CGFloat = min(max(value.location.x, 0), self.innerScale)
//           let y: CGFloat = min(max(value.location.y, 0), self.innerScale)
//
//           let ending = CGPoint(x: x, y: y)
//           let start = CGPoint(x: (self.innerScale) / 2, y: (self.innerScale) / 2)
//
//           let angle = self.angle(between: start, ending: ending)
//           self.value = CGFloat(Int(((angle / 360) * (self.maxTemperature / self.stepSize)))) / (self.maxTemperature / self.stepSize)
       }
    }
    
    var body: some View {
        Rotation()
    }
}

// Hold down the option key and drag to rotate
struct Rotation: View {
    enum RotationState {
        case inactive
        case rotating(angle: Angle)
        
        var rotationAngle: Angle {
            switch self {
            case .rotating(let angle):
                return angle
            default:
                return Angle.zero
            }
        }
    }
    
    var anglePublisher = PassthroughSubject<Angle, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    @GestureState var rotationState = RotationState.inactive
    @State var viewRotationState = Angle(degrees: 0.0)
    
    var totalRotation: CGFloat = CGFloat()
    var totalSegments: UInt = 4
    @State var currentSegment: UInt = 0
    
    init() {
        anglePublisher
            .lane("anglePublisher")
            .sink{ value in
                print("rotated: \(value.degrees) from top")
            }
            .store(in: &cancellables)
    }
    
    var rotationAngle: Angle {
        print("viewRotationState: \(viewRotationState.degrees) rotationAngle: \(rotationState.rotationAngle.degrees)")
        var ret = viewRotationState + rotationState.rotationAngle
        
        if ret.degrees < 0 {
            ret = Angle(degrees: 360.0) + ret
        }
        
        anglePublisher.send(ret)
        
//        // figure out the segment
//        let segmentAngle = 360.0 / Double(totalSegments)
//        currentSegment = UInt(ret.degrees / segmentAngle)
        
        return ret
    }
    
    var rotationHistory: [Angle] = []
    
    var body: some View {
        
        let rotationGesture = RotationGesture(minimumAngleDelta: Angle(degrees: 1))
            .updating($rotationState) { value, state, transation in
                state = .rotating(angle: value)
        }.onEnded { value in
            self.viewRotationState += value
            let segmentAngle = 360.0 / Double(self.totalSegments)
            let tempSegment = self.rotationAngle.degrees / segmentAngle
//            self.currentSegment = UInt()
            print("onEnded.value: \(value.degrees) viewRotationState: \(self.viewRotationState.degrees) segmentAngle: \(segmentAngle) tempSegment: \(tempSegment)")
        }
        
        return
            ZStack {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 350, height: 650)
                    .rotationEffect(rotationAngle)
                    .gesture(rotationGesture)
                
                VStack {
                    Text("Angle: \(rotationAngle.degrees)").font(.title)
                    Text("Segment: \(currentSegment)").font(.title)
//                    Text("\(rotationState.rotationAngle.degrees)").font(.title)
                }
            }
    }
}

struct PathNodeStruct<T: View> : Identifiable {
    var id: UUID = UUID()
    
    let view: T
    let rotationAngle: Angle
    let offset: (CGFloat, CGFloat)
}

enum ManeuverBearing : String {
    case LT
    case LB
    case S
    case RB
    case RT
    case LTA
    case RTA
    case K
    case LS
    case RS
    case X
    
    func getSymbolCharacter() -> String {
        switch(self) {
        case .LT:
            return "4"
        case .LB:
            return "7"
        case .S:
            return "8"
        case .RB:
            return "9"
        case .RT:
            return "6"
        case .RTA:
            return ";"
        case .LTA:
            return ":"
        case .K:
            return "2"
        case .LS:
            return "1"
        case .RS:
            return "3"
        case .X:
            return "5"
        }
    }
}

enum ManeuverDifficulty {
    
    case Red
    case White
    case Blue
    
    func color() -> Color {
        switch(self) {
        case .Red:
            return Color.red
        case .White:
            return Color.white
        case .Blue:
            return Color.blue
        }
    }
}

struct Maneuver: CustomStringConvertible {
    let speed: UInt
    let bearing: ManeuverBearing
    let difficulty: ManeuverDifficulty
    
    var description: String {
        return "\(speed)\(bearing.rawValue)"
    }
}

struct ManeuverDialSelection: View, CustomStringConvertible {
    let maneuver: Maneuver
    let size: CGFloat
    
    var body: some View {
        VStack {
            Text(maneuver.bearing.getSymbolCharacter())
                .font(.custom("xwing-miniatures", size: size))
                .foregroundColor(maneuver.difficulty.color())
                .padding(10)
            
            Text("\(maneuver.speed)")
                .font(.custom("KimberleyBl-Regular", size: size))
                .foregroundColor(maneuver.difficulty.color())
        }
        .border(Color.white)
    }
    
    var description: String {
        return "\(maneuver.speed)\(maneuver.bearing.rawValue)"
    }
}

struct AngleRange : Identifiable, CustomStringConvertible {
    let id: UUID = UUID()
    let start: CGFloat
    let end: CGFloat
    let mid: CGFloat
    let sector: UInt
    
    var description: String {
        return "\(start) \(mid) \(end) \(sector)"
    }
}

extension Array where Element == AngleRange {
    func getSegment(withAngle: CGFloat) -> UInt {
        print("withAngle: \(withAngle)")
        var ret: UInt = 0
        
        for (index, item) in self.enumerated() {
            print("Found \(item) at position \(index)")
            
            // Should pass in the negative threshold angle as an input param
            if (withAngle >= -22.5) && (withAngle < 360) {
                ret = 0
            }
            
            if (withAngle >= item.start) && (withAngle < item.end) {
                print("Found \(withAngle) at index \(index)")
                
                ret = UInt(index)
                return ret
            }
        }
        
        return ret
    }
}

struct MyShape : Shape {
    let parentWidth: CGFloat
    let parentHeight: CGFloat
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: parentWidth / 2, y:parentHeight / 2)
        
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(247.5),
                 endAngle: .degrees(292.5),
                 clockwise: false)
        
        p.addLine(to: center)
        p.closeSubpath()
        
        
//        return p.strokedPath(.init(lineWidth: 4)).fill(Color.red) as! Path
        return p
    }
}

struct MyCircle : View {
    let innerDiameter: CGFloat
    let rotationAngle: CGFloat
    
    var body: some View {
        return ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: self.innerDiameter,
                       height: self.innerDiameter,
                       alignment: .center)
                .rotationEffect(Angle.degrees(Double(self.rotationAngle)))
        }
    }
}

struct TestView: View {
    @State private var rotation = 0.0

    var body: some View {
        VStack {
            Slider(value: $rotation, in: 0...360, step: 1.0)
            Text("Up we go")
                .rotationEffect(.degrees(rotation), anchor: .topLeading)
        }
    }
}

// https://stackoverflow.com/questions/58494193/swiftui-rotationeffect-framing-and-offsetting
private struct SizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize,
                       nextValue: () -> CGSize)
    {
        value = nextValue()
    }
}

extension View {
    func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: SizeKey.self, value: proxy.size)
        })
        .onPreferenceChange(SizeKey.self) { size in
            binding.wrappedValue = size
        }
    }
}

struct Rotated<Rotated: View>: View {
    var view: Rotated
    var angle: Angle

    init(_ view: Rotated, angle: Angle = .degrees(-90)) {
        self.view = view
        self.angle = angle
    }

    @State private var size: CGSize = .zero

    var body: some View {
        // Rotate the frame, and compute the smallest integral frame that contains it
        let newFrame = CGRect(origin: .zero, size: size)
            .offsetBy(dx: -size.width/2, dy: -size.height/2)
            .applying(.init(rotationAngle: CGFloat(angle.radians)))
            .integral
        
        let v = view
            .fixedSize()                    // Don't change the view's ideal frame
            .captureSize(in: $size)         // Capture the size of the view's ideal frame
            .rotationEffect(angle)          // Rotate the view
            .frame(width: newFrame.width,   // And apply the new frame
                   height: newFrame.height)
        
        return v
    }
}

extension View {
    func rotated(_ angle: Angle = .degrees(-45)) -> some View {
        Rotated(self, angle: angle)
    }
}

func getCirclePoints(centerPoint point: CGPoint, radius: CGFloat, n: Int) -> [CGPoint] {
//    let points = getCirclePoints(centerPoint: CGPoint(x: 160, y: 240), radius: 120.0, n: 12)
    
    let result: [CGPoint] = stride(from: 0.0, to: 360.0, by: Double(360 / n)).map {
        let bearing = CGFloat($0) * .pi / 180
        let x = point.x + radius * cos(bearing)
        let y = point.y + radius * sin(bearing)
        return CGPoint(x: x, y: y)
    }
    
    return result
}


