import AppKit

// Entry point. All behavior lives in `Sources/`; this file just stands the app up
// and hands control to the composition root (`AppCoordinator`).

let app = NSApplication.shared
app.setActivationPolicy(.accessory)        // no Dock icon; lives in the menu bar

let coordinator = AppCoordinator()          // retained for the lifetime of the process
app.delegate = coordinator
app.run()
