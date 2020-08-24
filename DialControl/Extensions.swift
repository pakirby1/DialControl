//
//  Extensions.swift
//  DialControl
//
//  Created by Phil Kirby on 3/9/20.
//  Copyright © 2020 SoftDesk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension Binding {
    /// Execute block when value is changed.
    ///
    /// Example:
    ///
    ///     Slider(value: $amount.didSet { print($0) }, in: 0...10)
    func didSet(execute: @escaping (Value) ->Void) -> Binding {
        return Binding(
            get: {
                return self.wrappedValue
            },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

extension Binding {
    
    /// When the `Binding`'s `wrappedValue` changes, the given closure is executed.
    /// - Parameter closure: Chunk of code to execute whenever the value changes.
    /// - Returns: New `Binding`.
    func onUpdate(_ closure: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(get: {
            self.wrappedValue
        }, set: { newValue in
            self.wrappedValue = newValue
            closure(newValue)
        })
    }
}

extension Just {
    var asFuture: Future<Output, Never> {
        .init { promise in
            promise(.success(self.output))
        }
    }
}

extension EnvironmentValues {
    var theme: Int {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
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


extension Array where Element == AngleRange {
    func getSegment(withAngle: CGFloat) -> UInt {
        print("withAngle: \(withAngle)")
        var ret: UInt = 0
        
        for (index, item) in self.enumerated() {
            print("Found \(item) at position \(index)")
            
            // Should pass in the negative threshold angle as an input param
            // FIXME: Figure out the correct angles for segment 0 based on index 0
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

extension View {
    func rotated(_ angle: Angle = .degrees(-45)) -> some View {
        Rotated(self, angle: angle)
    }
}

extension StringProtocol {
    subscript(_ offset: Int) -> Element
    {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(_ range: Range<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: ClosedRange<Int>) -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1))
    }
    
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }
    
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count-range.lowerBound))
    }
}

extension View {
    func xPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point: (CGFloat, CGFloat) = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("x: \(point.0)")
        return point.0
    }

    func yPoint(_ withRadius: CGFloat, _ withAngle: CGFloat) -> CGFloat {
        let point: (CGFloat, CGFloat) = pointOnCircle(withRadius: withRadius, withAngle: withAngle)
        print("y: \(point.1)")
        return point.1
    }
    
    func pointOnCircle(withRadius: CGFloat, withAngle: CGFloat) -> (CGFloat, CGFloat) {
        let angle = CGFloat(withAngle - 90) * .pi / 180
        let x = withRadius * cos(angle)
        let y = withRadius * sin(angle)

//        return CGPoint(x: x, y: y)
        return (x, y)
    }
    
    func pointOnCircle(withRadius: CGFloat, withAngle: CGFloat) -> CGPoint {
        let angle = CGFloat(withAngle - 90) * .pi / 180
        let x = withRadius * cos(angle)
        let y = withRadius * sin(angle)

        return CGPoint(x: x, y: y)
//        return (x, y)
    }
}

func deg2rad(_ number: Double) -> Double {
    return number * .pi / 180
}

extension Shape {
    /// fills and strokes a shape
    public func fill<S:ShapeStyle>(_ fillContent: S,
                                   stroke: StrokeStyle) -> some View
    {
        ZStack {
            self.fill(fillContent)
            self.stroke(style:stroke)
        }
    }
    
    /// fills and strokes a shape
    public func fill<S:ShapeStyle>(_ fillContent: S,
                                   opacity: Double,
                                   strokeWidth: CGFloat,
                                   strokeColor: S) -> some View
    {
        ZStack {
            self.fill(fillContent).opacity(opacity)
            self.stroke(strokeColor, lineWidth: strokeWidth)
        }
    }
}

extension Image {
    
}

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}

extension String {
    func removeAll(character: String) -> String {
        return components(separatedBy: character).joined()
    }
}

extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}

extension SquadData {
    func getPilotState(index: Int) -> PilotState {
        let arr = Array(pilotState as! Set<PilotState>)
        return arr[index]
    }
    
    public var pilotStateArray: [PilotState] {
        return Array(pilotState as! Set<PilotState>)
    }
}
