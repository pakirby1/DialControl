import SwiftUI

///// Then in your `View`
//var body: some View {
//    WedgeShape()
//      .frame(width: 20, height: 20, alignment: .center)
//      .foregroundColor(.green)
//}

struct WedgeShape_New: Shape {
    let leftAngle: Double = 0.0
    let rightAngle: Double = 270.0
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let a0 = Angle(degrees: leftAngle)
        let a1 = Angle(degrees: rightAngle)
        let cen =  CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let r0 = rect.size.width/3.5
        let r1 = rect.size.width/2
        p.addArc(center: cen, radius: r0, startAngle: a0, endAngle: a1, clockwise: false)
        p.addArc(center: cen, radius: r1, startAngle: a1, endAngle: a0, clockwise: true)
        p.closeSubpath()
        
        return p
    }
}



struct WedgeShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()

        p.addArc(
            center: CGPoint(x: rect.size.width/2, y: rect.size.width/2),
            radius: rect.size.width/2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return p
    }
}

struct Wedge {
    var startAngle: Double
    var endAngle: Double
    var color: Color
}

struct WedgeView: View {
    var wedges = [
        Wedge(startAngle: 0, endAngle: 90, color: Color.red),
        Wedge(startAngle: 90, endAngle: 180, color: Color.green),
        Wedge(startAngle: 180, endAngle: 360, color: Color.blue)
    ]

    var body: some View {
        ZStack {
            ForEach(0 ..< wedges.count) {
                WedgeShape(
                    startAngle: Angle(degrees: self.wedges[$0].startAngle),
                    endAngle: Angle(degrees: self.wedges[$0].endAngle)
                )
                    .stroke(self.wedges[$0].color, lineWidth: 100).opacity(0.3)
            }
        }
    }
}
