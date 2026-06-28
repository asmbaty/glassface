import AppKit

/// Presents a fatal error as a modal alert, then terminates. One job, no state.
enum AlertPresenter {
    static func cameraPermissionDenied() {
        show("Camera access denied",
             "Enable camera access for GlassFace in System Settings → Privacy & Security → Camera, then relaunch.")
    }

    static func noCamera() {
        show("No camera found", "GlassFace couldn't find a usable camera on this Mac.")
    }

    private static func show(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Quit")
        alert.runModal()
        NSApp.terminate(nil)
    }
}
