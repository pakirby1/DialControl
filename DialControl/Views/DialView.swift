//
//  DialView.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TimelaneCombine

struct DialView: View {

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
    
    var anglePublisher = PassthroughSubject<Angle, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
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
        
        anglePublisher
            .lane("anglePublisher")
            .sink{ value in
                print("rotated: \(value.degrees)")
            }
            .store(in: &cancellables)
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
                SelectionIndicator(parentWidth: g.size.width,
                        parentHeight: g.size.height,
                        radius: (self.innerDiameter / 2) + 20)
                    .fill(Color.red)
            }
            
            ZStack {
                DialCircle(innerDiameter: self.innerDiameter, rotationAngle: self.currentTemperature)
                
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
                        
                        self.anglePublisher.send(Angle(degrees: Double(angle)))
                    }
                )
        
            VStack {
                buildSymbolView()
                    .frame(width: 32, height: 40, alignment: .center)
//                    .border(Color.white)
                
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
    
    func getCirclePoints(centerPoint point: CGPoint, radius: CGFloat, n: Int) -> [CGPoint] {
        let result: [CGPoint] = stride(from: 0.0, to: 360.0, by: Double(360 / n)).map {
            let bearing = CGFloat($0) * .pi / 180
            let x = point.x + radius * cos(bearing)
            let y = point.y + radius * sin(bearing)
            return CGPoint(x: x, y: y)
        }
        
        return result
    }
    
    func buildSymbolView() -> AnyView {
        func buildSFSymbolView() -> AnyView {
            return AnyView(Image(systemName: "arrow.up")
                .font(.system(size: 36.0, weight: .bold))
                .foregroundColor(lambda_Shuttle_Maneuvers[Int(currentSegment)].difficulty.color()))
//                .border(Color.white))
        }
        
        func buildArrowView() -> AnyView {
            return AnyView(UpArrowView(color: lambda_Shuttle_Maneuvers[Int(currentSegment)].difficulty.color()))
//                .fill()
        }
        
        // For some reason, the top of the arrow gets cut off for the "8" (Straight) bearing in x-wing font.
        if lambda_Shuttle_Maneuvers[Int(currentSegment)].bearing == .S {
//            return buildSFSymbolView()
            return buildArrowView()
            
        } else {
            return AnyView(Text(lambda_Shuttle_Maneuvers[Int(currentSegment)].bearing.getSymbolCharacter())
                                .font(.custom("xwing-miniatures", size: 30))
                                .frame(width: 32, height: 40, alignment: .center)
                                .foregroundColor(lambda_Shuttle_Maneuvers[Int(currentSegment)].difficulty.color())
                                .padding(2))
//                                .border(Color.white))
        }
    }
}

struct SelectionIndicator : Shape {
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

struct DialCircle : View {
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
            
//            UpArrowView()
        }
    }
}



