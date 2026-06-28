import AppKit

/// Actions the menu bar can request. The controller depends on this narrow protocol
/// rather than the concrete app coordinator (Interface Segregation / Dependency Inversion).
protocol StatusMenuControllerDelegate: AnyObject {
    var isHeartGestureEnabled: Bool { get }
    func statusMenuDidRequestIncreaseOpacity()
    func statusMenuDidRequestDecreaseOpacity()
    func statusMenuDidToggleHeartGesture()
    func statusMenuDidRequestQuit()
}

/// Builds and owns the menu bar status item and its menu, forwarding clicks to its delegate.
final class StatusMenuController: NSObject {
    weak var delegate: StatusMenuControllerDelegate?

    private var statusItem: NSStatusItem?
    private var opacityItem: NSMenuItem?
    private var heartItem: NSMenuItem?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = GhostImageRenderer.menuBarImage(size: 18)
        item.menu = buildMenu()
        statusItem = item
    }

    func updateOpacity(_ opacity: Float) {
        opacityItem?.title = "Opacity: \(Int((opacity * 100).rounded()))%"
    }

    func updateHeartState(_ enabled: Bool) {
        heartItem?.state = enabled ? .on : .off
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let opacity = NSMenuItem(title: "Opacity: —", action: nil, keyEquivalent: "")
        opacity.isEnabled = false
        menu.addItem(opacity)
        opacityItem = opacity

        menu.addItem(.separator())
        menu.addItem(makeItem("Increase Opacity", #selector(increase), key: "="))
        menu.addItem(makeItem("Decrease Opacity", #selector(decrease), key: "-"))

        let presets = NSMenuItem(title: "Set Opacity: ⌃⌥⌘ 1–9, 0 = 100%", action: nil, keyEquivalent: "")
        presets.isEnabled = false
        menu.addItem(presets)

        menu.addItem(.separator())
        let heart = makeItem("Heart Gesture", #selector(toggleHeart), key: "")
        heart.state = (delegate?.isHeartGestureEnabled ?? true) ? .on : .off
        menu.addItem(heart)
        heartItem = heart

        menu.addItem(.separator())
        menu.addItem(makeItem("Quit GlassFace", #selector(quit), key: "q"))
        return menu
    }

    private func makeItem(_ title: String, _ selector: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        if !key.isEmpty { item.keyEquivalentModifierMask = [.control, .option, .command] }
        item.target = self
        return item
    }

    @objc private func increase() { delegate?.statusMenuDidRequestIncreaseOpacity() }
    @objc private func decrease() { delegate?.statusMenuDidRequestDecreaseOpacity() }
    @objc private func toggleHeart() { delegate?.statusMenuDidToggleHeartGesture() }
    @objc private func quit() { delegate?.statusMenuDidRequestQuit() }
}
