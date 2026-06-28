import Cocoa
import AVFoundation
import Carbon.HIToolbox

// MARK: - Settings

let defaultOpacity: Float = 0.35
let opacityStep: Float = 0.10

// Hot key identifiers
private let kHotKeyQuit: UInt32 = 1
private let kHotKeyUp: UInt32 = 2
private let kHotKeyDown: UInt32 = 3

// Global handle so the C event handler can reach the delegate.
weak var sharedDelegate: AppDelegate?

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []
    var previewLayers: [AVCaptureVideoPreviewLayer] = []
    let session = AVCaptureSession()
    var opacity: Float = defaultOpacity

    var statusItem: NSStatusItem?
    var opacityMenuItem: NSMenuItem?
    var hotKeyRefs: [EventHotKeyRef?] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        sharedDelegate = self
        setupMenuBar()
        registerHotKeys()
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.setupCamera()
                    self.setupWindows()
                } else {
                    self.showPermissionError()
                }
            }
        }
    }

    // MARK: Camera

    func frontCamera() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        return discovery.devices.first
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
            ?? AVCaptureDevice.default(for: .video)
    }

    func setupCamera() {
        guard let device = frontCamera(),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showCameraError()
            return
        }
        session.beginConfiguration()
        session.addInput(input)
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    // MARK: Windows

    func setupWindows() {
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .screenSaver                 // floats above normal windows
            window.ignoresMouseEvents = true            // <-- clicks pass through; Mac stays usable
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.setFrame(screen.frame, display: true)

            let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.clear.cgColor

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            preview.opacity = opacity
            preview.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

            // Mirror the feed (like looking in a mirror).
            if let conn = preview.connection, conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = true
            }

            view.layer?.addSublayer(preview)
            previewLayers.append(preview)

            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    // MARK: Opacity

    func changeOpacity(by delta: Float) {
        opacity = min(1.0, max(0.0, opacity + delta))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayers.forEach { $0.opacity = opacity }
        CATransaction.commit()
        updateMenu()
    }

    @objc func increaseOpacity() { changeOpacity(by: opacityStep) }
    @objc func decreaseOpacity() { changeOpacity(by: -opacityStep) }

    // MARK: Menu bar

    /// A monochrome ghost glyph (template image) for the menu bar — matches the app icon.
    func ghostMenuBarImage(size: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let s = rect.width

            let gw = s * 0.72, gh = s * 0.82
            let gx = (s - gw) / 2
            let gBottom = s * 0.09
            let gTop = gBottom + gh
            let domeR = gw / 2
            let domeCY = gTop - domeR
            let nBumps = 3
            let bumpW = gw / CGFloat(nBumps)
            let bumpR = bumpW / 2
            let waveTopY = gBottom + bumpR

            let ghost = CGMutablePath()
            ghost.move(to: CGPoint(x: gx, y: domeCY))
            ghost.addArc(center: CGPoint(x: s / 2, y: domeCY), radius: domeR,
                         startAngle: .pi, endAngle: 0, clockwise: true)
            ghost.addLine(to: CGPoint(x: gx + gw, y: waveTopY))
            for i in 0..<nBumps {
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
        img.isTemplate = true
        return img
    }

    func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = ghostMenuBarImage(size: 18)
        }

        let menu = NSMenu()
        let opacityItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        opacityItem.isEnabled = false
        menu.addItem(opacityItem)
        opacityMenuItem = opacityItem
        menu.addItem(.separator())

        let up = NSMenuItem(title: "Increase Opacity", action: #selector(increaseOpacity), keyEquivalent: "=")
        up.keyEquivalentModifierMask = [.control, .option, .command]
        up.target = self
        menu.addItem(up)

        let down = NSMenuItem(title: "Decrease Opacity", action: #selector(decreaseOpacity), keyEquivalent: "-")
        down.keyEquivalentModifierMask = [.control, .option, .command]
        down.target = self
        menu.addItem(down)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit GlassFace", action: #selector(quit), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = [.control, .option, .command]
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
        updateMenu()
    }

    func updateMenu() {
        opacityMenuItem?.title = "Opacity: \(Int((opacity * 100).rounded()))%"
    }

    @objc func quit() { NSApp.terminate(nil) }

    // MARK: Global hot keys (Carbon — no Accessibility permission needed)

    func registerHotKeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            DispatchQueue.main.async {
                switch hkID.id {
                case kHotKeyQuit: sharedDelegate?.quit()
                case kHotKeyUp:   sharedDelegate?.increaseOpacity()
                case kHotKeyDown: sharedDelegate?.decreaseOpacity()
                default: break
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)

        let mods: UInt32 = UInt32(controlKey | optionKey | cmdKey)
        register(keyCode: UInt32(kVK_ANSI_Q), id: kHotKeyQuit, mods: mods)
        register(keyCode: UInt32(kVK_ANSI_Equal), id: kHotKeyUp, mods: mods)
        register(keyCode: UInt32(kVK_ANSI_Minus), id: kHotKeyDown, mods: mods)
    }

    func register(keyCode: UInt32, id: UInt32, mods: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x47464143), id: id) // 'GFAC'
        var ref: EventHotKeyRef?
        RegisterEventHotKey(keyCode, mods, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        hotKeyRefs.append(ref)
    }

    // MARK: Errors

    func showPermissionError() {
        alert("Camera access denied",
              "Enable camera access for GlassFace in System Settings → Privacy & Security → Camera, then relaunch.")
    }

    func showCameraError() {
        alert("No camera found", "GlassFace couldn't find a usable camera on this Mac.")
    }

    func alert(_ title: String, _ message: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = message
        a.addButton(withTitle: "Quit")
        a.runModal()
        NSApp.terminate(nil)
    }
}

// MARK: - Entry point

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon; lives in the menu bar
let delegate = AppDelegate()
app.delegate = delegate
app.run()
