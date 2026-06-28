import Cocoa

// Draws the GlassFace app icon — a frosted-glass ghost (the "transparent face") on a
// vivid gradient, with one camera-lens eye to keep the camera theme — and assembles
// AppIcon.icns via `iconutil`. Run once via build.sh.

func makeIcon(_ px: Int) -> CGImage {
    let s = CGFloat(px)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    // --- Rounded-rect background with a vivid diagonal gradient ---
    let bg = CGRect(x: 0, y: 0, width: s, height: s).insetBy(dx: s * 0.04, dy: s * 0.04)
    let bgPath = CGPath(roundedRect: bg, cornerWidth: s * 0.22, cornerHeight: s * 0.22, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath); ctx.clip()
    let grad = CGGradient(colorsSpace: cs,
                          colors: [rgb(0.29, 0.18, 0.74),   // indigo
                                   rgb(0.77, 0.18, 0.62),   // magenta
                                   rgb(1.00, 0.42, 0.42)]    // coral
                            as CFArray,
                          locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

    // Soft glow behind the ghost so it pops off the gradient.
    let glow = CGGradient(colorsSpace: cs,
                          colors: [rgb(1, 1, 1, 0.45), rgb(1, 1, 1, 0)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: s / 2, y: s * 0.55), startRadius: 0,
                           endCenter: CGPoint(x: s / 2, y: s * 0.55), endRadius: s * 0.40, options: [])
    ctx.restoreGState()

    // --- Ghost body (dome top + scalloped bottom) ---
    let gw = s * 0.46
    let gh = s * 0.60
    let gx = (s - gw) / 2
    let gBottom = s * 0.20
    let gTop = gBottom + gh
    let domeR = gw / 2
    let domeCY = gTop - domeR
    let nBumps = 4
    let bumpW = gw / CGFloat(nBumps)
    let bumpR = bumpW / 2
    let waveTopY = gBottom + bumpR

    let ghost = CGMutablePath()
    ghost.move(to: CGPoint(x: gx, y: domeCY))
    ghost.addArc(center: CGPoint(x: s / 2, y: domeCY), radius: domeR,
                 startAngle: .pi, endAngle: 0, clockwise: true)   // dome over the top
    ghost.addLine(to: CGPoint(x: gx + gw, y: waveTopY))           // right side down
    for i in 0..<nBumps {                                          // scalloped bottom, right→left
        let cx = gx + gw - bumpR - CGFloat(i) * bumpW
        ghost.addArc(center: CGPoint(x: cx, y: waveTopY), radius: bumpR,
                     startAngle: 0, endAngle: .pi, clockwise: true)
    }
    ghost.closeSubpath()                                          // left side up

    // Frosted-glass fill with a soft drop shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.04,
                  color: rgb(0.15, 0.05, 0.25, 0.45))
    ctx.addPath(ghost)
    ctx.setFillColor(rgb(1, 1, 1, 0.92))
    ctx.fillPath()
    ctx.restoreGState()

    // Inner vertical gradient (top bright → bottom lavender) for a glassy sheen.
    ctx.saveGState()
    ctx.addPath(ghost); ctx.clip()
    let sheen = CGGradient(colorsSpace: cs,
                           colors: [rgb(1, 1, 1, 0.55), rgb(0.78, 0.74, 0.95, 0)] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 0, y: gTop),
                           end: CGPoint(x: 0, y: gBottom), options: [])
    ctx.restoreGState()

    // --- Eyes ---
    let eyeY = domeCY + s * 0.02
    let eyeDX = gw * 0.20
    let eyeR = s * 0.05
    func disc(_ center: CGPoint, _ r: CGFloat, _ color: CGColor) {
        ctx.setFillColor(color)
        ctx.fillEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r))
    }
    // Left: plain glassy eye.
    let leftEye = CGPoint(x: s / 2 - eyeDX, y: eyeY)
    disc(leftEye, eyeR, rgb(0.16, 0.13, 0.28))
    disc(CGPoint(x: leftEye.x - eyeR * 0.3, y: leftEye.y + eyeR * 0.3), eyeR * 0.32, rgb(1, 1, 1, 0.9))

    // Right: camera-lens eye (concentric rings + highlight).
    let rightEye = CGPoint(x: s / 2 + eyeDX, y: eyeY)
    disc(rightEye, eyeR * 1.15, rgb(0.16, 0.13, 0.28))
    disc(rightEye, eyeR * 0.78, rgb(0.30, 0.55, 0.95))
    disc(rightEye, eyeR * 0.42, rgb(0.10, 0.12, 0.22))
    disc(CGPoint(x: rightEye.x - eyeR * 0.35, y: rightEye.y + eyeR * 0.35), eyeR * 0.22, rgb(1, 1, 1, 0.95))

    return ctx.makeImage()!
}

func writePNG(_ img: CGImage, to path: String) {
    let rep = NSBitmapImageRep(cgImage: img)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let iconset = "AppIcon.iconset"
try? fm.removeItem(atPath: iconset)
try! fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let specs: [(Int, Bool)] = [(16, false), (16, true), (32, false), (32, true),
                            (128, false), (128, true), (256, false), (256, true),
                            (512, false), (512, true)]
for (base, retina) in specs {
    let scale = retina ? 2 : 1
    let px = base * scale
    let name = "icon_\(base)x\(base)\(retina ? "@2x" : "").png"
    writePNG(makeIcon(px), to: "\(iconset)/\(name)")
}

let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset, "-o", "AppIcon.icns"]
try! p.run()
p.waitUntilExit()
try? fm.removeItem(atPath: iconset)
print("Wrote AppIcon.icns")
