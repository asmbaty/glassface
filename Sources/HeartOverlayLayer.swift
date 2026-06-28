import AppKit
import QuartzCore

/// The red heart drawn over the feed. Owns its own appearance, positioning, and
/// show/hide animations — callers just say where it is and whether it's visible.
final class HeartOverlayLayer: CAShapeLayer {
    private let heartSize: CGFloat

    init(size: CGFloat) {
        heartSize = size
        super.init()

        bounds = CGRect(x: 0, y: 0, width: size * 0.95, height: size)
        path = HeartShape.path(in: bounds)
        fillColor = NSColor(calibratedRed: 1.0, green: 0.18, blue: 0.33, alpha: 0.92).cgColor
        strokeColor = NSColor(white: 1, alpha: 0.85).cgColor
        lineWidth = 2
        opacity = 0
        shadowColor = NSColor(calibratedRed: 1.0, green: 0.10, blue: 0.30, alpha: 1).cgColor
        shadowRadius = 18
        shadowOpacity = 0.9
        shadowOffset = .zero
    }

    /// Core Animation copies layers for its presentation tree via this initializer.
    override init(layer: Any) {
        heartSize = (layer as? HeartOverlayLayer)?.heartSize ?? 0
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Move instantly (no implicit animation) so the heart tracks the hands without lag.
    func move(to center: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        position = center
        CATransaction.commit()
    }

    func setVisible(_ visible: Bool) {
        fade(to: visible ? 1 : 0)
        if visible { startPulse() } else { stopPulse() }
    }

    private func fade(to value: Float) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.18)
        opacity = value
        CATransaction.commit()
    }

    private func startPulse() {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.duration = 0.6
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        add(pulse, forKey: "pulse")
    }

    private func stopPulse() {
        removeAnimation(forKey: "pulse")
    }
}
