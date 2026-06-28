import AppKit
import AVFoundation
import Carbon.HIToolbox

/// Composition root. Builds the collaborators, wires them together, and orchestrates the
/// cross-cutting flows (camera permission, opacity, hot keys). It holds no UI drawing or
/// detection logic itself — each of those lives in its own single-responsibility type.
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private let config = AppConfiguration()
    private let camera = CameraService()
    private let recognizer: HeartGestureRecognizer
    private let overlay: OverlayCoordinator
    private let hotKeys = HotKeyCenter()
    private let menu = StatusMenuController()

    private var heartGestureEnabled = true

    override init() {
        recognizer = HeartGestureRecognizer(config: config)
        overlay = OverlayCoordinator(config: config)
        super.init()
        camera.frameConsumer = recognizer
        recognizer.delegate = self
        menu.delegate = self
    }

    // MARK: App lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.install()
        menu.updateOpacity(overlay.opacity)
        configureHotKeys()

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async { self?.cameraAccessResolved(granted: granted) }
        }
    }

    private func cameraAccessResolved(granted: Bool) {
        guard granted else { AlertPresenter.cameraPermissionDenied(); return }
        do {
            try camera.configure()
        } catch {
            AlertPresenter.noCamera()
            return
        }
        overlay.buildOverlays(session: camera.session)
        camera.start()
    }

    // MARK: Opacity orchestration

    /// Single funnel for every opacity change, wherever it originates.
    private func setOpacity(_ value: Float) {
        let applied = overlay.setOpacity(value)
        menu.updateOpacity(applied)
        camera.setRunning(applied > 0)            // camera genuinely off at 0% (green light out)
        if applied == 0 { overlay.hideHeart() }   // no frames will arrive to fade it
    }

    private func increaseOpacity() { setOpacity(overlay.opacity + config.opacityStep) }
    private func decreaseOpacity() { setOpacity(overlay.opacity - config.opacityStep) }

    // MARK: Hot keys

    private func configureHotKeys() {
        hotKeys.install()
        hotKeys.bind(keyCode: kVK_ANSI_Q) { [weak self] in self?.quit() }
        hotKeys.bind(keyCode: kVK_ANSI_Equal) { [weak self] in self?.increaseOpacity() }
        hotKeys.bind(keyCode: kVK_ANSI_Minus) { [weak self] in self?.decreaseOpacity() }

        // Number keys jump straight to a level: 1…9 → 10%…90%, 0 → 100%.
        let presets: [(keyCode: Int, level: Float)] = [
            (kVK_ANSI_1, 0.1), (kVK_ANSI_2, 0.2), (kVK_ANSI_3, 0.3), (kVK_ANSI_4, 0.4),
            (kVK_ANSI_5, 0.5), (kVK_ANSI_6, 0.6), (kVK_ANSI_7, 0.7), (kVK_ANSI_8, 0.8),
            (kVK_ANSI_9, 0.9), (kVK_ANSI_0, 1.0)
        ]
        for preset in presets {
            hotKeys.bind(keyCode: preset.keyCode) { [weak self] in self?.setOpacity(preset.level) }
        }
    }

    private func quit() { NSApp.terminate(nil) }
}

// MARK: - Recognizer → overlay

extension AppCoordinator: HeartGestureRecognizerDelegate {
    func recognizer(_ recognizer: HeartGestureRecognizer, didUpdate gesture: HeartGesture?) {
        overlay.updateHeart(gesture)
    }
}

// MARK: - Menu bar actions

extension AppCoordinator: StatusMenuControllerDelegate {
    var isHeartGestureEnabled: Bool { heartGestureEnabled }

    func statusMenuDidRequestIncreaseOpacity() { increaseOpacity() }
    func statusMenuDidRequestDecreaseOpacity() { decreaseOpacity() }

    func statusMenuDidToggleHeartGesture() {
        heartGestureEnabled.toggle()
        recognizer.isEnabled = heartGestureEnabled
        menu.updateHeartState(heartGestureEnabled)
        if !heartGestureEnabled { overlay.hideHeart() }
    }

    func statusMenuDidRequestQuit() { quit() }
}
