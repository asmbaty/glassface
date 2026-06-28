import AppKit
import AVFoundation

/// One screen's overlay: the transparent window, the camera preview layer, and the heart.
/// Translates Vision-normalized gesture points into this screen's layer coordinates.
final class ScreenOverlay {
    private let window: OverlayWindow
    private let previewLayer: AVCaptureVideoPreviewLayer
    private let heart: HeartOverlayLayer

    init(screen: NSScreen, session: AVCaptureSession, opacity: Float, heartSize: CGFloat) {
        window = OverlayWindow(screen: screen)

        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.opacity = opacity
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true     // selfie view
        }
        view.layer?.addSublayer(previewLayer)

        heart = HeartOverlayLayer(size: heartSize)
        view.layer?.addSublayer(heart)            // above the feed

        window.contentView = view
    }

    func present() {
        window.orderFrontRegardless()
    }

    func setOpacity(_ value: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.opacity = value
        CATransaction.commit()
    }

    /// Position the heart between the two gesture points (Vision-normalized, bottom-left origin).
    /// `layerPointConverted` accounts for the preview's aspect-fill gravity and mirroring.
    func positionHeart(_ gesture: HeartGesture) {
        let index = previewLayer.layerPointConverted(fromCaptureDevicePoint: gesture.indexMidpoint)
        let thumb = previewLayer.layerPointConverted(fromCaptureDevicePoint: gesture.thumbMidpoint)
        heart.move(to: CGPoint(x: (index.x + thumb.x) / 2, y: (index.y + thumb.y) / 2))
    }

    func setHeartVisible(_ visible: Bool) {
        heart.setVisible(visible)
    }
}
