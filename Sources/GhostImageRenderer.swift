import AppKit

/// Draws the monochrome ghost template image used for the menu bar (matches the app icon).
/// Stateless rendering helper — one job, no dependencies.
enum GhostImageRenderer {
    static func menuBarImage(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let s = rect.width

            let gw = s * 0.72, gh = s * 0.82
            let gx = (s - gw) / 2
            let gBottom = s * 0.09
            let gTop = gBottom + gh
            let domeR = gw / 2
            let domeCY = gTop - domeR
            let bumpCount = 3
            let bumpW = gw / CGFloat(bumpCount)
            let bumpR = bumpW / 2
            let waveTopY = gBottom + bumpR

            let ghost = CGMutablePath()
            ghost.move(to: CGPoint(x: gx, y: domeCY))
            ghost.addArc(center: CGPoint(x: s / 2, y: domeCY), radius: domeR,
                         startAngle: .pi, endAngle: 0, clockwise: true)
            ghost.addLine(to: CGPoint(x: gx + gw, y: waveTopY))
            for i in 0..<bumpCount {
                let cx = gx + gw - bumpR - CGFloat(i) * bumpW
                ghost.addArc(center: CGPoint(x: cx, y: waveTopY), radius: bumpR,
                             startAngle: 0, endAngle: .pi, clockwise: true)
            }
            ghost.closeSubpath()

            ctx.addPath(ghost)
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fillPath()

            // Punch out the two eyes so the menu bar shows through.
            ctx.setBlendMode(.clear)
            let eyeY = domeCY + s * 0.02
            let eyeDX = gw * 0.18
            let eyeR = s * 0.075
            for dx in [-eyeDX, eyeDX] {
                ctx.fillEllipse(in: CGRect(x: s / 2 + dx - eyeR, y: eyeY - eyeR,
                                           width: 2 * eyeR, height: 2 * eyeR))
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
