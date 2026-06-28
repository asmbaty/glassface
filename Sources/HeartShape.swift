import CoreGraphics

/// Pure geometry: a heart path (point at the bottom, two lobes on top) in a y-up
/// coordinate space. Stateless, so it's trivial to reuse and reason about.
enum HeartShape {
    static func path(in rect: CGRect) -> CGPath {
        let w = rect.width, h = rect.height
        let minX = rect.minX, minY = rect.minY, maxX = rect.maxX, maxY = rect.maxY
        let midX = rect.midX

        let path = CGMutablePath()
        path.move(to: CGPoint(x: midX, y: minY))                            // bottom tip
        path.addCurve(to: CGPoint(x: maxX, y: minY + h * 0.70),             // up the right side
                      control1: CGPoint(x: midX + w * 0.13, y: minY + h * 0.32),
                      control2: CGPoint(x: maxX, y: minY + h * 0.48))
        path.addCurve(to: CGPoint(x: midX, y: minY + h * 0.74),             // right lobe → center dip
                      control1: CGPoint(x: maxX, y: maxY),
                      control2: CGPoint(x: midX + w * 0.12, y: maxY))
        path.addCurve(to: CGPoint(x: minX, y: minY + h * 0.70),             // center dip → left lobe
                      control1: CGPoint(x: midX - w * 0.12, y: maxY),
                      control2: CGPoint(x: minX, y: maxY))
        path.addCurve(to: CGPoint(x: midX, y: minY),                        // down the left side
                      control1: CGPoint(x: minX, y: minY + h * 0.48),
                      control2: CGPoint(x: midX - w * 0.13, y: minY + h * 0.32))
        path.closeSubpath()
        return path
    }
}
