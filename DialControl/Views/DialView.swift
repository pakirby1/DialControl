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
    
    @State var currentSegment: UInt = 0
    @State var topSegment: UInt = 0
    @Binding var currentManeuver: String
    var displayAngleRanges: Bool = true
    
    var maneuvers: [String] = ["1LT", "1LB", "1LS", "1RB", "2LT", "2LB", "2RS", "2RB"]
    
//    case E      // Left Talon
//    case L      // Left Sloop
//    case T      // Left Turn
//    case B      // Left Bank
//    case A      // Left Reverse
//    case O      // Stop
//    case S      // Reverse
//    case F      // Forward
//    case R      // Right Talon
//    case P      // Right Sloop
//    case Y      // Right Turn
//    case N      // Right Bank
//    case D      // Right Reverse
//    case K      // K Turn
    
    let lambda_Shuttle_Maneuvers2: [Maneuver] = [Maneuver(speed: 0, bearing: .O, difficulty: .R),
                                                Maneuver(speed: 1, bearing: .B, difficulty: .B),
                                                Maneuver(speed: 1, bearing: .F, difficulty: .B),
                                                Maneuver(speed: 1, bearing: .N, difficulty: .B),
                                                Maneuver(speed: 2, bearing: .T, difficulty: .R),
                                                Maneuver(speed: 2, bearing: .B, difficulty: .W),
                                                Maneuver(speed: 2, bearing: .F, difficulty: .B),
                                                Maneuver(speed: 2, bearing: .N, difficulty: .W),
                                                Maneuver(speed: 2, bearing: .Y, difficulty: .R),
                                                Maneuver(speed: 3, bearing: .T, difficulty: .R),
                                                Maneuver(speed: 3, bearing: .F, difficulty: .W),
                                                Maneuver(speed: 3, bearing: .Y, difficulty: .R)]
    
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
    
    private var angles: [Range<CGFloat>] = []
    private var maneuverList: [Maneuver] = []
    
    var totalSegments: CGFloat {
        CGFloat(maneuvers.count)
    }
    
    private var innerDiameter: CGFloat {
        return outerDiameter - indicatorLength
    }
    
    private var radius: CGFloat {
        return innerDiameter / 2
    }

    mutating func buildDial(dial: [String]) {
        let count = dial.count
        let sectorAngle: CGFloat = CGFloat(360) / CGFloat(count) // 30
        
        var lower = sectorAngle / 2 // 15
        var upper = lower // 15
        let range: Range<CGFloat> = -lower..<upper // -15..<15
        
        angles.append(range)
        
//        0 : Range(-10.5..<10.5)
//          - lowerBound : -10.5
//          - upperBound : 10.5
//        ▿ 1 : Range(10.5..<31.5)
//          - lowerBound : 10.5
//          - upperBound : 31.5
//        ▿ 2 : Range(10.5..<31.5)
//          - lowerBound : 10.5
//          - upperBound : 31.5
//        ▿ 3 : Range(10.5..<31.5)
//          - lowerBound : 10.5
//          - upperBound : 31.5
//        ▿ 4 : Range(10.5..<31.5)
//          - lowerBound : 10.5
//          - upperBound : 31.5
//
        dial.enumerated().forEach { index, value in
            if (index > 0) {
                lower = upper
                upper = lower + sectorAngle
                let range: Range<CGFloat> = lower..<upper
                angles.append(range)
            }
            
            maneuverList.append(Maneuver.buildManeuver(maneuver: value))
        }
        
        self.pathNodes = self.buildPathNodes(radius: self.textCircleRadius,
                                    maneuvers: maneuverList)
    }
    
    var anglePublisher = PassthroughSubject<Angle, Never>()
    private var cancellables: Set<AnyCancellable> = []
    // @ObservedObject var timeCounter = TimeCounter()
    private var pathNodes: [PathNodeStruct<ManeuverDialSelection>] = []
    let dial: [String]
    
    init(temperature: CGFloat,
         diameter: CGFloat,
         currentManeuver: Binding<String>,
         dial: [String],
         displayAngleRanges: Bool)
    {
        print("DialView.init()")
        self.initialTemperature = temperature
        self.outerDiameter = diameter
        self.displayAngleRanges = displayAngleRanges
        
        self._currentManeuver = currentManeuver // Have to use `_` character to set the binding
        
        self.dial = dial
        buildDial(dial: dial)
        
        for (index, item) in self.angles.enumerated() {
            let lower = item.lowerBound
            let mid = (item.lowerBound + item.upperBound) / 2

            self.angleRanges
                .append(AngleRange(start: CGFloat(lower),
                                   end: CGFloat(item.upperBound),
                                   mid: CGFloat(mid),
                                   sector: UInt(index)))
        }
        
        anglePublisher
            .lane("anglePublisher")
            .sink{ value in
                print("rotated: \(value.degrees)")
            }
            .store(in: &cancellables)
    }
    
    
    private func buildPathNodes(radius: CGFloat, maneuvers: [Maneuver]) -> [PathNodeStruct<ManeuverDialSelection>]
    {
        var currentAngle = Angle(degrees: 0)
        
        // Read angle from AngleRanges instead
        let segmentAngle = CGFloat(360) / CGFloat(maneuvers.count)
        
        let pathNodes: [PathNodeStruct<ManeuverDialSelection>] = maneuvers.map{
            let view = ManeuverDialSelection(maneuver: $0, size: 30)
            
            // 0 degrees in SwiftUI is at the pi / 2 (90 clockwise) location, so add
            // -90 to get the correct location
            let rotationAngle = Angle(degrees: currentAngle.degrees)
            let textRadius = radius - 40
            
            let offset: (CGFloat, CGFloat) = pointOnCircle(withRadius: textRadius, withAngle: CGFloat(rotationAngle.degrees))
            currentAngle.degrees += Double(segmentAngle)
            
            print("\(#function) \(view): \(rotationAngle.degrees) (x: \(offset.0), y: \(offset.1)) \(currentAngle.degrees)")
            
            return buildPathNode(view: view,
                                 rotationAngle: rotationAngle,
                                 offset: offset,
                                 sectorAngle: currentAngle)
        }
        
        return pathNodes
    }
    
    private func buildPathNode<T: View>(view: T,
                                        rotationAngle: Angle,
                                        offset: (CGFloat, CGFloat),
                                        sectorAngle: Angle) -> PathNodeStruct<T>
    {
        let pathNode = PathNodeStruct(view: view,
                                      rotationAngle: rotationAngle,
                                      offset: offset,
                                      sectorAngle: sectorAngle)
        
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
        return self.radius - 25
    }
    
    var dashedStyle : StrokeStyle {
        StrokeStyle(lineWidth: self.indicatorLength,
                    lineCap: .butt,
                    lineJoin: .miter,
                    dash: [4])
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
            ZStack {
                DialCircle(innerDiameter: self.innerDiameter,
                           rotationAngle: self.currentTemperature)

                ForEach(pathNodes, id:\.id) { node in
                    node.view
                        .rotated(Angle.degrees(node.rotationAngle.degrees))
                        .offset(x: node.offset.0,
                                y: node.offset.1)
                        .rotationEffect(Angle.degrees(Double(self.currentTemperature)))
                }
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
                        let start = CGPoint(x: self.radius, y: self.radius)

                        print("start=\(start)")
                        print("ending=\(ending)")
                        
                        let angle = self.angle(between: start, ending: ending)
                        self.value = CGFloat(Int(((angle / 360) * (self.maxTemperature / self.stepSize)))) / (self.maxTemperature / self.stepSize)
                        
                        self.currentSegment = self.calculateCurrentSegment(percentage: self.value)
                        
                        self.currentSegment = self.getSector(baseline: start.x,
                                                    x: ending.x,
                                                    angleFromBaseline: angle)
                        
                        self.currentTemperature = self.value * self.maxTemperature
                        
                        self.topSegment = UInt(self.angleRanges.getSegment(withAngle: self.currentTemperature))
                        
                        print("angle: \(angle) oldAngle: \(self.oldAngle) self.value= \(self.value) self.currentSegment= \(self.currentSegment) rotatingClockwise: \(self.rotatingClockwise)")
                        
                        self.rotatingClockwise = (angle - self.oldAngle) > 0
                        self.oldAngle = angle
                        
                        self.anglePublisher.send(Angle(degrees: Double(angle)))
                        self.currentManeuver = self.maneuverList[Int(self.currentSegment)].description
                    }
                )
        
            VStack {
                buildSymbolView()
                    .frame(width: 32, height: 40, alignment: .center)
//                    .border(Color.white)
                
                Text("\(maneuverList[Int(currentSegment)].description)")
                    .font(.largeTitle)
                    .foregroundColor(maneuverList[Int(currentSegment)].difficulty.color)
                    .fontWeight(.semibold)

//                Text("\(currentTemperature, specifier: "%.1f") \u{2103} \n segment: \(currentSegment)")
//                    .font(.body)
//                    .foregroundColor(Color.white)
            }
            
            GeometryReader { g in
                SelectionIndicator(sectorAngle: self.pathNodes[0].sectorAngle.degrees,
                                       radius: self.radius)
                .fill(Color.clear,
                      opacity: 0.5,
                      strokeWidth: 3,
                      strokeColor: Color.white)
            }
        }
//        .border(Color.blue)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            InnerCircle(innerDiameter: self.innerDiameter,
                        currentManeuver: self.$currentManeuver,
                        dial: self.dial)
            
//            innerCircle

            if (displayAngleRanges) {
                VStack {
                    ForEach(self.angleRanges, id:\.id) { angle in
                        Text("\(angle.start)..\(angle.mid)<\(angle.end) \(angle.sector) \(self.getManeuver(sector: angle.sector))")
                    }
                }.offset(x: 0, y: -325)
            }
        }
        .onAppear(perform: {
            let percentage = self.initialTemperature / self.maxTemperature
            self.value = percentage
            self.currentSegment = self.calculateCurrentSegment(percentage: self.value)
        })
    }
    
    func getManeuver(sector: UInt) -> String {
        return maneuverList[Int(sector)].description
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
                .foregroundColor(maneuverList[Int(currentSegment)].difficulty.color))
        }
        
        func buildArrowView() -> AnyView {
            return AnyView(UpArrowView(color: maneuverList[Int(currentSegment)].difficulty.color))
        }
        
        func buildTextFontView(baselineOffset: CGFloat = 0) -> AnyView {
            return AnyView(Text(maneuverList[Int(currentSegment)].bearing.getSymbolCharacter()).baselineOffset(baselineOffset)
                .font(.custom("xwing-miniatures", size: 30))
                .frame(width: 32, height: 40, alignment: .center)
                .foregroundColor(maneuverList[Int(currentSegment)].difficulty.color)
                .padding(2))
        }
        
        // For some reason, the top of the arrow gets cut off for the "8" (Straight) bearing in x-wing font. See baselineOffset
        if maneuverList[Int(currentSegment)].bearing == .F {
//            return buildSFSymbolView()
            return AnyView(buildTextFontView(baselineOffset: -10))
        } else if maneuverList[Int(currentSegment)].bearing == .K {
            return AnyView(buildTextFontView(baselineOffset: -10))
        } else {
            return AnyView(buildTextFontView())
        }
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
        }
    }
}


