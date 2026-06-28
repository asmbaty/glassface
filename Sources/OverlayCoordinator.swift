import AppKit
import AVFoundation

/// Owns every screen's overlay. Applies opacity across all of them and runs the
/// heart show/hide state machine from recognizer updates. It renders; it does not
/// manage the camera session lifecycle (that's the app coordinator's job).
final class OverlayCoordinator {
    private(set) var opacity: Float

    private let config: AppConfiguration
    private var overlays: [ScreenOverlay] = []
    private var heartVisible = false
    private var missFrames = 0

    init(config: AppConfiguration) {
        self.config = config
        opacity = config.defaultOpacity
    }

    func buildOverlays(session: AVCaptureSession) {
        overlays = NSScreen.screens.map {
            ScreenOverlay(screen: $0, session: session, opacity: opacity, heartSize: config.heartSize)
        }
        overlays.forEach { $0.present() }
    }

    /// Clamps, applies, and returns the resulting opacity.
    @discardableResult
    func setOpacity(_ value: Float) -> Float {
        opacity = min(1, max(0, value))
        overlays.forEach { $0.setOpacity(opacity) }
        return opacity
    }

    /// Drive the heart from a recognizer result (`nil` = no heart this frame).
    func updateHeart(_ gesture: HeartGesture?) {
        if let gesture = gesture {
            missFrames = 0
            overlays.forEach { $0.positionHeart(gesture) }
            if !heartVisible {
                heartVisible = true
                overlays.forEach { $0.setHeartVisible(true) }
            }
        } else {
            missFrames += 1
            if heartVisible && missFrames > config.heartHideGraceFrames {
                hideHeart()
            }
        }
    }

    func hideHeart() {
        guard heartVisible else { return }
        heartVisible = false
        overlays.forEach { $0.setHeartVisible(false) }
    }
}
