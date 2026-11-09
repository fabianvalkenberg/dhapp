import SwiftUI

/// Matches the notch SVG: a white rectangle with a curved "tab" cutout at the top center.
/// SVG viewport 466x36, curve from x=158 down to y=31, flat to x=276, back up to x=299.
struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Start top-left
        path.move(to: CGPoint(x: 0, y: 0))

        // Straight line to where curve starts (34% from left)
        let curveStartX = w * 0.339
        path.addLine(to: CGPoint(x: curveStartX, y: 0))

        // Curve down to the bottom of the notch opening
        let bottomY = h * 0.86  // depth of the notch
        let leftBottomX = w * 0.386
        path.addCurve(
            to: CGPoint(x: leftBottomX, y: bottomY),
            control1: CGPoint(x: curveStartX + (leftBottomX - curveStartX) * 0.4, y: 0),
            control2: CGPoint(x: curveStartX + (leftBottomX - curveStartX) * 0.7, y: bottomY)
        )

        // Flat bottom of notch
        let rightBottomX = w * 0.592
        path.addLine(to: CGPoint(x: rightBottomX, y: bottomY))

        // Curve back up to top
        let curveEndX = w * 0.642
        path.addCurve(
            to: CGPoint(x: curveEndX, y: 0),
            control1: CGPoint(x: rightBottomX + (curveEndX - rightBottomX) * 0.3, y: bottomY),
            control2: CGPoint(x: rightBottomX + (curveEndX - rightBottomX) * 0.6, y: 0)
        )

        // Straight line to top-right
        path.addLine(to: CGPoint(x: w, y: 0))

        // Down to bottom-right
        path.addLine(to: CGPoint(x: w, y: h))

        // Across to bottom-left
        path.addLine(to: CGPoint(x: 0, y: h))

        path.closeSubpath()
        return path
    }
}
