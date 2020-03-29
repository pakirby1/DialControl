import SwiftUI

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
