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
