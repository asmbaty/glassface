import AppKit

/// A borderless, transparent, click-through window pinned across one screen.
/// `ignoresMouseEvents` is what keeps the Mac fully usable underneath the overlay.
final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver                       // floats above normal windows
        ignoresMouseEvents = true                  // clicks/keys pass through to apps below
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        setFrame(screen.frame, display: false)
    }
}
