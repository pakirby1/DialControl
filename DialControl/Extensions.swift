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

