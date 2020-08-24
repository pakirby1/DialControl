//
//  InnerCircle.swift
//  DialControl
//
//  Created by Phil Kirby on 4/5/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct InnerCircle: View {
    let innerDiameter: CGFloat
    
    private let maxTemperature: CGFloat = 360
    private let stepSize: CGFloat = 0.5
    var maneuvers: [String] = ["1LT", "1LB", "1LS", "1RB", "2LT", "2LB", "2RS", "2RB"]
    private var angleRanges: [AngleRange] = []
    private var pathNodes: [PathNodeStruct<ManeuverDialSelection>] = []
    private var maneuverList: [Maneuver] = []
    @State var currentSegment: UInt = 0
    @State private var oldCoordinate: (CGFloat, CGFloat) = (0.0, 0.0)
    @State private var oldAngle: CGFloat = 0.0
    @State private var value: CGFloat = 0
    @State private var currentTemperature : CGFloat = 0.0
    @State var topSegment: UInt = 0
    @State private var rotatingClockwise = true
    var anglePublisher = PassthroughSubject<Angle, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private var angles: [Range<CGFloat>] = []
    @Binding var currentManeuver: String
    
    init(innerDiameter: CGFloat,
         currentManeuver: Binding<String>,
         dial: [String]) {
        self.innerDiameter = innerDiameter
        self._currentManeuver = currentManeuver
        
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
        
        for i in 0...angleRanges.count - 1 {
            print("\(maneuverList[i]) \(angleRanges[i])")
        }
        
        /*
         Command-Control Space to bring up emoji keyboard
         1T -11.25 0.0 11.25 0      ✅
         1B 11.25 22.5 33.75 1      ❗️4F (360-22.5 = 337.5 => 4F)
         1F 33.75 45.0 56.25 2      ❗️3Y (360-45.0 = 315.0 => 3Y)
         1N 56.25 67.5 78.75 3      ❗️3N (360-67.5 = 292.5 => 3N)
         1Y 78.75 90.0 101.25 4
         2T 101.25 112.5 123.75 5
         2B 123.75 135.0 146.25 6
         2F 146.25 157.5 168.75 7
         2N 168.75 180.0 191.25 8
         2Y 191.25 202.5 213.75 9
         3T 213.75 225.0 236.25 10
         3B 236.25 247.5 258.75 11
         3F 258.75 270.0 281.25 12
         3N 281.25 292.5 303.75 13
         3Y 303.75 315.0 326.25 14
         4F 326.25 337.5 348.75 15
         
         360-Mid(Maneuver) = angle
         */
        let sector = getSector(maneuver: currentManeuver.wrappedValue)
        let angle = self.angleRanges[sector]
        let newAngle = 360 - angle.mid
        print("angle: \(angle) maneuver: \(currentManeuver.wrappedValue) newAngle: \(newAngle)")
        self._currentTemperature = State(initialValue: newAngle)
        self._currentSegment = State(initialValue: UInt(sector))
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
    
    var textCircleRadius: CGFloat {
        return self.radius - 25
    }
    
    var body: some View {
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
                        let fraction = self.maxTemperature / self.stepSize
                        
                        self.value = CGFloat(Int(((angle / 360) * (fraction)))) / (fraction)
                        
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
//                    Text("\(currentManeuver)")
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
                    .trim(from: 0, to: 1)
                    .fill(Color.gray,
                          opacity: 0.5,
                          strokeWidth: 3,
                          strokeColor: Color.white)
            }
        }
//        .border(Color.blue)
    }
    
    private var radius: CGFloat {
        return innerDiameter / 2
    }
    
    var totalSegments: CGFloat {
        CGFloat(maneuvers.count)
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
    
    func getSector(baseline: CGFloat, x: CGFloat, angleFromBaseline: CGFloat) -> UInt {
        var newAngle: CGFloat = angleFromBaseline

        // if we are going CW the angleFromBaseline will be closer to 360 (viewing high sectors)
        // if we are going CCW the angleFromBaseline will be closer to 0 (viewing low sectors)
        newAngle = 360.0 - angleFromBaseline
    
        let segment = angleRanges.getSegment(withAngle: newAngle)
        
        return UInt(segment)
    }
    
    func getSector(maneuver: String) -> Int {
        if let sector = maneuverList
            .enumerated()
            .filter({ $0.element.description == maneuver })
            .map({ $0.offset })
            .first
        {
            return sector
        } else {
            return 0
        }
    }
    
    func calculateCurrentSegment(percentage: CGFloat) -> UInt {
        UInt((self.value * self.totalSegments).rounded(.down))
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
            
            // For some reason, the top of the arrow gets cut off for the "8" (Straight) bearing in x-wing font.
            let maneuverIndex = Int(currentSegment)
        
            if maneuverList[Int(maneuverIndex)].bearing == .F {
                //            return buildSFSymbolView()
                return AnyView(buildTextFontView(baselineOffset: -10))
            } else if maneuverList[Int(maneuverIndex)].bearing == .K {
                return AnyView(buildTextFontView(baselineOffset: -10))
            } else {
                return AnyView(buildTextFontView())
            }
    }
}

struct OverlayContentView: View {
    @State var showOverlay = false
    @State var curColor = Color.blue
    @State var text = "Hello World"
    
    var body: some View {
        Text(text)
            .frame(width: 100, height: 100)
            .background(curColor)
            .foregroundColor(Color.white)
            .cornerRadius(20)
//            .onTapGesture { self.showOverlay.toggle() }
            .overlay( ArcSelectionView(isShowing: self.$showOverlay, curColor: self.$curColor) )
    }
}

struct ArcSelectionView: View {
    @Binding var isShowing : Bool
    @Binding var curColor : Color
    
    let colors = [Color.blue, Color.red, Color.green, Color.yellow]
    
    var body: some View {
        ZStack {
            ForEach(1 ..< 5, id: \.self) { item in
                Circle()
                    .trim(from: self.isShowing ? CGFloat((Double(item) * 0.25) - 0.25) : CGFloat(Double(item) * 0.25),
                          to: CGFloat(Double(item) * 0.25))
                    .stroke(self.colors[item - 1], lineWidth: 30)
                    .frame(width: 300, height: 300)
                    .animation(.linear(duration: 0.4))
                    .onTapGesture {
                        self.curColor = self.colors[item - 1]
                        self.isShowing.toggle()
                }
            }
        }
        .opacity(self.isShowing ? 1 : 0)
        .rotationEffect(.degrees(self.isShowing ? 0 : 180))
        .animation(.linear(duration: 0.5))
    }
}

