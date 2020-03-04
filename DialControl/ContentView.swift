//
//  ContentView.swift
//  DialControl
//
//  Created by Phil Kirby on 2/15/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import SwiftUI
import Combine

class Test : ObservableObject {
    @Published var temperature: CGFloat = 0.0
}

struct ContentView: View {
    let test = Test()
    
    var body: some View {
        let binding = Binding<CGFloat>(
            get: { self.test.temperature },
            set: { self.test.temperature = $0} )

        return TemperatureDial(temperature: 0,
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
        anglePublisher.sink{ value in
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

struct TemperatureDial: View {

    @State private var value: CGFloat = 0
    @State private var oldCoordinate: (CGFloat, CGFloat) = (0.0, 0.0)
    @State private var oldAngle: CGFloat = 0.0
    @State private var rotatingClockwise = true
    
    private let initialTemperature: CGFloat
    private let outerDiameter: CGFloat
    private let indicatorLength: CGFloat = 25
    private let maxTemperature: CGFloat = 360
    private let stepSize: CGFloat = 0.5
    private var ranges: [CGFloat] = []
    private var angleRanges: [AngleRange] = []
    private var temps: [Range<CGFloat>] = [0..<45,
                                           45..<90,
                                           90..<135,
                                           135..<180,
                                           180..<225,
                                           225..<270,
                                           270..<315,
                                           315..<360
                                            ]
    
    // sector can stradle the baseline (x = 0)
//    private var newTemps: [Range<CGFloat>] = [-22.5..<22.5,
//                                              22.5..<67.5,
//                                              67.5..<112.5,
//                                              112.5..<157.5,
//                                              157.5..<202.5,
//                                              202.5..<247.5,
//                                              247.5..<292.5,
//                                              292.5..<337.5
//                                            ]

    
    @State var currentSegment: UInt = 0
    @State var topSegment: UInt = 0
    
    var maneuvers: [String] = ["1LT", "1LB", "1LS", "1RB", "2LT", "2LB", "2RS", "2RB"]
    
//    let Newmaneuvers: [Maneuver] = [Maneuver(speed: 1, bearing: .LT, difficulty: .White),
//                                    Maneuver(speed: 1, bearing: .LB, difficulty: .Blue),
//                                    Maneuver(speed: 1, bearing: .LS, difficulty: .Red),
//                                    Maneuver(speed: 1, bearing: .RB, difficulty: .Blue),
//                                    Maneuver(speed: 2, bearing: .LTA, difficulty: .Red),
//                                    Maneuver(speed: 2, bearing: .RT, difficulty: .White),
//                                    Maneuver(speed: 2, bearing: .RS, difficulty: .Red),
//                                    Maneuver(speed: 2, bearing: .K, difficulty: .Red)
//                                    ]
    
    let lambda_Shuttle_Maneuvers: [Maneuver] = [Maneuver(speed: 0, bearing: .X, difficulty: .Red),
                                                Maneuver(speed: 1, bearing: .LB, difficulty: .Blue),
                                                Maneuver(speed: 1, bearing: .S, difficulty: .Blue),
                                                Maneuver(speed: 1, bearing: .RB, difficulty: .Blue),
                                                Maneuver(speed: 2, bearing: .LT, difficulty: .Red),
                                                Maneuver(speed: 2, bearing: .LB, difficulty: .White),
                                                Maneuver(speed: 2, bearing: .S, difficulty: .Blue),
                                                Maneuver(speed: 2, bearing: .RB, difficulty: .White),
                                                Maneuver(speed: 2, bearing: .RT, difficulty: .Red),
                                                Maneuver(speed: 3, bearing: .LT, difficulty: .Red),
                                                Maneuver(speed: 3, bearing: .S, difficulty: .White),
                                                Maneuver(speed: 3, bearing: .RT, difficulty: .Red)]
    
    private var lambda_Shuttle_Angles: [Range<CGFloat>] = [-15..<15,
      15..<45,
      45..<75,
      75..<105,
      105..<135,
      135..<165,
      165..<195,
      195..<225,
      225..<255,
      255..<285,
      285..<315,
      315..<345
    ]
    
    var totalSegments: CGFloat {
        CGFloat(maneuvers.count)
    }
    
    private var innerDiameter: CGFloat {
        return outerDiameter - indicatorLength
    }

    mutating func buildSectorsOdd() {
        let numberOfSections = 8
        
        // 1 - Define sector length
        let fanWidth: CGFloat = CGFloat.pi * 2 / 8
        print("fanWidth= \(fanWidth)")
        
        // 2 - Set initial midpoint
        var mid: CGFloat = 0
        
        // 3 - Iterate through all sectors
        for index in 1...numberOfSections {
            print("mid= \(mid)")
            var angleRange = AngleRange(start: mid - (fanWidth/2),
                                        end: mid + (fanWidth/2),
                                        mid: mid,
                                        sector: UInt(index))
            print(angleRange)
            
            mid -= fanWidth
            
            print("mid= \(mid)")
            
            if (angleRange.start < -CGFloat.pi) {
                mid = -mid
                print("mid= \(mid)")
                
                mid -= fanWidth
                print("mid= \(mid)")
            }
            
            angleRanges.append(angleRange)
        }
        
        angleRanges.forEach{print($0)}
    }

//    mutating func buildSectorsEven() {
//        let numberOfSections = 8
//
//        // 1 - Define sector length
//        let fanWidth: CGFloat = CGFloat.pi * 2 / 8
//        print("fanWidth= \(fanWidth)")
//
//        // 2 - Set initial midpoint
//        var mid: CGFloat = 0
//
//        // 3 - Iterate through all sectors
//        for index in 1...numberOfSections {
//            print("mid= \(mid)")
//            var angleRange = AngleRange(start: mid - (fanWidth/2),
//                                        end: mid + (fanWidth/2),
//                                        mid: mid,
//                                        sector: UInt(index))
//            print(angleRange)
//
//            if (angleRange.end - fanWidth < - CGFloat.pi) {
//                mid = CGFloat.pi
//                angleRange.mid = mid;
//                angleRange.start = fabsf(sector.maxValue);
//
//            }
//            mid -= fanWidth;
//
//
//            angleRanges.append(angleRange)
//        }
//
//        angleRanges.forEach{print($0)}
//    }
    init(temperature: CGFloat, diameter: CGFloat) {
        self.initialTemperature = temperature
        self.outerDiameter = diameter
        let x = self.innerDiameter
        print("x: \(x)")
        
        self.ranges = stride(from: 0.0, to: 360.0, by: 45.0)
            .map{ CGFloat($0) }

        for (index, item) in self.lambda_Shuttle_Angles.enumerated() {
            let lower = item.lowerBound
            _ = item.upperBound
            let mid = (item.lowerBound + item.upperBound) / 2

            self.angleRanges.append(AngleRange(start: lower, end: item.upperBound, mid: mid, sector: UInt(index)))
        }
        
    }

    private func buildManeuverViews_Old(radius: CGFloat) -> [PathNodeStruct<Text>] {
        var currentAngle = Angle(degrees: -90)
        let segmentAngle = Double(360 / maneuvers.count)
        
        let pathNodes: [PathNodeStruct<Text>] = maneuvers.map{
            let view = Text($0)
            let rotationAngle = Angle(degrees: currentAngle.degrees)
            let offset = pointOnCircle(withRadius: radius, withAngle: CGFloat(rotationAngle.degrees))
            currentAngle.degrees += segmentAngle
            
            return buildPathNode(view: view,
                                 rotationAngle: rotationAngle,
                                 offset: offset)
        }
        
        return pathNodes
    }
    
    private func buildManeuverViews_New(radius: CGFloat,
                                        maneuvers: [Maneuver]) -> [PathNodeStruct<ManeuverDialSelection>] {
        var currentAngle = Angle(degrees: 0)
        let segmentAngle = Double(360 / maneuvers.count)
        
        let pathNodes: [PathNodeStruct<ManeuverDialSelection>] = maneuvers.map{
            let view = ManeuverDialSelection(maneuver: $0, size: 40)
            
            // 0 degrees in SwiftUI is at the pi / 2 (90 clockwise) location, so add
            // -90 to get the correct location
            let rotationAngle = Angle(degrees: currentAngle.degrees)
            let textRadius = radius - 40
            
            let offset = pointOnCircle(withRadius: textRadius, withAngle: CGFloat(rotationAngle.degrees))
            currentAngle.degrees += segmentAngle
            
            print("\(#function) \(view): \(rotationAngle.degrees) (x: \(offset.0), y: \(offset.1)) \(currentAngle.degrees)")
            
            return buildPathNode(view: view,
                                 rotationAngle: rotationAngle,
                                 offset: offset)
        }
        
        return pathNodes
    }
    
    private func buildPathNode<T: View>(view: T,
                                        rotationAngle: Angle,
                                        offset: (CGFloat, CGFloat)) -> PathNodeStruct<T>
    {
        let pathNode = PathNodeStruct(view: view,
                                      rotationAngle: rotationAngle,
                                      offset: offset)
        
        return pathNode
    }
    
    private func angle(between starting: CGPoint, ending: CGPoint) -> CGFloat {
        let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
        let radians = atan2(center.y, center.x)
        var degrees = 90 + (radians * 180 / .pi)

        if degrees < 0 {
            degrees += 360
        }

        return degrees
    }

    func calculateCurrentSegment(percentage: CGFloat) -> UInt {
        UInt((self.value * self.totalSegments).rounded(.down))
    }
    
    @State private var currentTemperature : CGFloat = 0.0
    @State private var rotationAngle: CGFloat = 0.0
    
    var textCircleRadius: CGFloat {
        return (self.innerDiameter / 2) - 25
    }
    
    var dashedStyle : StrokeStyle {
        StrokeStyle(lineWidth: self.indicatorLength,
                    lineCap: .butt,
                    lineJoin: .miter,
                    dash: [4])
    }
    
    func pointOnCircle(withRadius: CGFloat, withAngle: CGFloat) -> (CGFloat, CGFloat) {
        let angle = CGFloat(withAngle - 90) * .pi / 180
        let x = withRadius * cos(angle)
        let y = withRadius * sin(angle)
        
        return (x, y)
    }
    
    func getOffsetForIndex(withRadius: CGFloat,
                           numPoints: Int,
                           index: Int) -> CGPoint
    {
        let points = getCirclePoints(centerPoint: CGPoint(x: 0, y: 0),
                                     radius: withRadius,
                                     n: numPoints)
        
        return points[index]
    }
    
    func xPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("x: \(point.0)")
        return point.0
    }
    
    func yPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("y: \(point.1)")
        return point.1
    }
    
    func getSector(baseline: CGFloat, x: CGFloat, angleFromBaseline: CGFloat) -> UInt {
        var newAngle: CGFloat = angleFromBaseline

        // if we are going CW the angleFromBaseline will be closer to 360 (viewing high sectors)
        // if we are going CCW the angleFromBaseline will be closer to 0 (viewing low sectors)
        newAngle = 360.0 - angleFromBaseline
    
        let segment = angleRanges.getSegment(withAngle: newAngle)
        
        return UInt(segment)
    }

    var innerCircle: some View {
        ZStack {
            GeometryReader { g in
                MyShape(parentWidth: g.size.width,
                        parentHeight: g.size.height,
                        radius: (self.innerDiameter / 2) + 20)
                    .fill(Color.red)
            }
            
            ZStack {
                MyCircle(innerDiameter: self.innerDiameter, rotationAngle: self.currentTemperature)
                
//                Rectangle()
//                    .fill(Color.red)
//                    .frame(width: self.innerDiameter / 3,
//                           height: self.innerDiameter / 3,
//                           alignment: .center)
//                    .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
                
//                Text("1")
//                    .font(.title)
//                    .offset(x: 0, y: -self.textCircleRadius)
//                    .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
//
                ForEach(self.buildManeuverViews_New(radius: self.textCircleRadius, maneuvers: lambda_Shuttle_Maneuvers), id:\.id) { node in
                    node.view
//                        .font(.custom("KimberleyBl-Regular", size: 36))
//                        .font(.title)
                        .rotated(Angle.degrees(node.rotationAngle.degrees))
                        .offset(x: node.offset.0,
                                y: node.offset.1)
                        .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
                }
                
//                Text("2")
//                    .font(.title)
//                    .rotated(Angle.degrees(90.0))
//                    .offset(x: xPoint(self.textCircleRadius, 90.0),
//                            y: yPoint(self.textCircleRadius, 90.0))
//                    .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
                
//                ForEach(self.maneuvers, id:\.self) { maneuver in
//                    let point = getOffsetForIndex(withRadius: CGFloatself.textCircleRadius, numPoints: maneuvers.count, index: 0)
//                    Text("2")
//
//                }
                                
//                Text("3")
//                    .font(.title)
//                    .rotated(Angle.degrees(60))
////                    .offset(x: xPoint(self.textCircleRadius, 60.0),
////                            y: yPoint(self.textCircleRadius, 60.0))
//                    .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
                
//                Text("6")
//                    .font(.title)
//                    .offset(x: 0, y: self.textCircleRadius)
//                    .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
            }
            .gesture(
                    DragGesture().onChanged() { value in
                        print("self.oldCoordinate: x=\(self.oldCoordinate.0) y=\(self.oldCoordinate.1)")
                        print("self.oldAngle = \(self.oldAngle)")
                        
                        print("value.location.x=\(value.location.x)")
                        print("value.location.y=\(value.location.y)")
                        
                        let x: CGFloat = min(max(value.location.x, 0), self.innerDiameter)
                        let y: CGFloat = min(max(value.location.y, 0), self.innerDiameter)

                        let ending = CGPoint(x: x, y: y)
                        let start = CGPoint(x: (self.innerDiameter) / 2, y: (self.innerDiameter) / 2)

                        print("start=\(start)")
                        print("ending=\(ending)")
                        
                        let angle = self.angle(between: start, ending: ending)
                        self.value = CGFloat(Int(((angle / 360) * (self.maxTemperature / self.stepSize)))) / (self.maxTemperature / self.stepSize)
                        
                        self.currentSegment = self.calculateCurrentSegment(percentage: self.value)
                        
                        self.currentSegment = self.getSector(baseline: start.x,
                                                    x: ending.x,
                                                    angleFromBaseline: angle)
                        
//                        self.topSegment = UInt(self.totalSegments - 1) - self.currentSegment
                        self.currentTemperature = self.value * self.maxTemperature
                        
                        self.topSegment = UInt(self.angleRanges.getSegment(withAngle: self.currentTemperature))
                        
                        print("angle: \(angle) oldAngle: \(self.oldAngle) self.value= \(self.value) self.currentSegment= \(self.currentSegment) rotatingClockwise: \(self.rotatingClockwise)")
                        
                        self.rotatingClockwise = (angle - self.oldAngle) > 0
                        self.oldAngle = angle
                    }
                )
        
            VStack {
                Text(lambda_Shuttle_Maneuvers[Int(currentSegment)].bearing.getSymbolCharacter())
                    .font(.custom("xwing-miniatures", size: 40))
                    .foregroundColor(lambda_Shuttle_Maneuvers[Int(currentSegment)].difficulty.color())
                    .padding(10)
                
                Text("\(lambda_Shuttle_Maneuvers[Int(currentSegment)].description)")
                    .font(.largeTitle)
                    .foregroundColor(Color.white)
                    .fontWeight(.semibold)
                
                Text("\(currentTemperature, specifier: "%.1f") \u{2103} \n segment: \(currentSegment)")
                    .font(.body)
                    .foregroundColor(Color.white)
            }
        }
        .border(Color.blue)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            innerCircle
            
//            // remaining temp
//            Circle()
//                .stroke(Color.blue, style: dashedStyle)
//                .frame(width: self.outerDiameter, height: self.outerDiameter, alignment: .center)
//
//            // current temp
//            Circle()
//                .trim(from: 0.0, to: self.value)
//                .stroke(Color.red, style: dashedStyle)
//                .rotationEffect(.degrees(-90))
//                .frame(width: self.outerDiameter, height: self.outerDiameter, alignment: .center)
            
            VStack {
                ForEach(self.angleRanges, id:\.id) { angle in
                    Text("\(angle.start)..\(angle.mid)<\(angle.end) \(angle.sector) \(self.getManeuver(sector: angle.sector))")
                }
            }.offset(x: 0, y: -375)
        }
        .onAppear(perform: {
            let percentage = self.initialTemperature / self.maxTemperature
            self.value = percentage
            self.currentSegment = self.calculateCurrentSegment(percentage: self.value)
        })
    }
    
    func getManeuver(sector: UInt) -> String {
        return lambda_Shuttle_Maneuvers[Int(sector)].description
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


