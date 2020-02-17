////
////  Test.swift
////  DialControl
////
////  Created by Phil Kirby on 2/16/20.
////  Copyright © 2020 SoftDesk. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//func centreArcPerpendicular(text str: String,
//                            context: CGContext,
//                            radius r: CGFloat,
//                            angle theta: CGFloat,
//                            colour c: UIColor,
//                            font: UIFont,
//                            clockwise: Bool)
//{
//    // *******************************************************
//    // This draws the String str around an arc of radius r,
//    // with the text centred at polar angle theta
//    // *******************************************************
//
//    let characters: [String] = str.map { String($0) } // An array of single character strings, each character in str
//    let l = characters.count
//    let attributes = [NSAttributedString.Key.font: font]
//
//    var arcs: [CGFloat] = [] // This will be the arcs subtended by each character
//    var totalArc: CGFloat = 0 // ... and the total arc subtended by the string
//
//    // Calculate the arc subtended by each letter and their total
//    for i in 0 ..< l {
//        arcs += [chordToArc(characters[i].size(withAttributes: attributes).width, radius: r)]
//        totalArc += arcs[i]
//    }
//
//    // Are we writing clockwise (right way up at 12 o'clock, upside down at 6 o'clock)
//    // or anti-clockwise (right way up at 6 o'clock)?
//    let direction: CGFloat = clockwise ? -1 : 1
//    let slantCorrection: CGFloat = clockwise ? -.pi / 2 : .pi / 2
//
//    // The centre of the first character will then be at
//    // thetaI = theta - totalArc / 2 + arcs[0] / 2
//    // But we add the last term inside the loop
//    var thetaI = theta - direction * totalArc / 2
//
//    for i in 0 ..< l {
//        thetaI += direction * arcs[i] / 2
//        // Call centerText with each character in turn.
//        // Remember to add +/-90º to the slantAngle otherwise
//        // the characters will "stack" round the arc rather than "text flow"
//        centre(text: characters[i], context: context, radius: r, angle: thetaI, colour: c, font: font, slantAngle: thetaI + slantCorrection)
//        // The centre of the next character will then be at
//        // thetaI = thetaI + arcs[i] / 2 + arcs[i + 1] / 2
//        // but again we leave the last term to the start of the next loop...
//        thetaI += direction * arcs[i] / 2
//    }
//}
//
//func chordToArc(_ chord: CGFloat, radius: CGFloat) -> CGFloat {
//    // *******************************************************
//    // Simple geometry
//    // *******************************************************
//    return 2 * asin(chord / (2 * radius))
//}
//
//func centre(text str: String, context: CGContext, radius r: CGFloat, angle theta: CGFloat, colour c: UIColor, font: UIFont, slantAngle: CGFloat) {
//    // *******************************************************
//    // This draws the String str centred at the position
//    // specified by the polar coordinates (r, theta)
//    // i.e. the x= r * cos(theta) y= r * sin(theta)
//    // and rotated by the angle slantAngle
//    // *******************************************************
//
//    // Set the text attributes
//    let attributes = [NSAttributedStringKey.foregroundColor: c, NSAttributedStringKey.font: font]
//    //let attributes = [NSForegroundColorAttributeName: c, NSFontAttributeName: font]
//    // Save the context
//    context.saveGState()
//    // Undo the inversion of the Y-axis (or the text goes backwards!)
//    context.scaleBy(x: 1, y: -1)
//    // Move the origin to the centre of the text (negating the y-axis manually)
//    context.translateBy(x: r * cos(theta), y: -(r * sin(theta)))
//    // Rotate the coordinate system
//    context.rotate(by: -slantAngle)
//    // Calculate the width of the text
//    let offset = str.size(withAttributes: attributes)
//    // Move the origin by half the size of the text
//    context.translateBy (x: -offset.width / 2, y: -offset.height / 2) // Move the origin to the centre of the text (negating the y-axis manually)
//    // Draw the text
//    str.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
//    // Restore the context
//    context.restoreGState()
//}
//
//// *******************************************************
//// Playground code to test
//// *******************************************************
//let size = CGSize(width: 256, height: 256)
//
//UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
//let context = UIGraphicsGetCurrentContext()!
//// *******************************************************************
//// Scale & translate the context to have 0,0
//// at the centre of the screen maths convention
//// Obviously change your origin to suit...
//// *******************************************************************
//context.translateBy (x: size.width / 2, y: size.height / 2)
//context.scaleBy(x: 1, y: -1)
//
//centreArcPerpendicular(text: "Hello round 🌏 world", context: context, radius: 100, angle: 0, colour: UIColor.red, font: UIFont.systemFont(ofSize: 16), clockwise: true)
//centreArcPerpendicular(text: "Anticlockwise", context: context, radius: 100, angle: CGFloat(-M_PI_2), colour: UIColor.red, font: UIFont.systemFont(ofSize: 16), clockwise: false)
//centre(text: "Hello flat world", context: context, radius: 0, angle: 0 , colour: UIColor.yellow, font: UIFont.systemFont(ofSize: 16), slantAngle: .pi / 4)
//
//
//let image = UIGraphicsGetImageFromCurrentImageContext()
//UIGraphicsEndImageContext()
//
//U
