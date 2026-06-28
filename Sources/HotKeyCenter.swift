import Carbon.HIToolbox

/// Registers global hot keys via Carbon (no Accessibility permission needed) and routes
/// each to a closure. All bindings use the ⌃⌥⌘ modifier so they never hijack plain typing.
/// Reaches back into the instance through the event handler's `userData` — no globals.
final class HotKeyCenter {
    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []
    private var nextID: UInt32 = 1

    private let signature = OSType(0x47464143)   // 'GFAC'
    private static let modifiers = UInt32(controlKey | optionKey | cmdKey)

    /// Installs the shared event handler. Call once before binding keys.
    func install() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let event = event, let userData = userData else { return noErr }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            center.dispatch(id.id)
            return noErr
        }, 1, &spec, context, nil)
    }

    /// Binds ⌃⌥⌘ + `keyCode` (a `kVK_ANSI_*` value) to `handler`.
    func bind(keyCode: Int, handler: @escaping () -> Void) {
        let id = nextID
        nextID += 1
        handlers[id] = handler

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        RegisterEventHotKey(UInt32(keyCode), Self.modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
    }

    private func dispatch(_ id: UInt32) {
        guard let handler = handlers[id] else { return }
        DispatchQueue.main.async(execute: handler)
    }
}
