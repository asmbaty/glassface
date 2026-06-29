using System;
using System.Collections.Generic;
using System.Windows.Forms;

namespace GlassFace;

/// <summary>
/// Registers global hot keys via Win32 <c>RegisterHotKey</c> and routes each to a callback.
/// All bindings use the <b>Ctrl+Alt+Shift</b> modifier (the Windows analog of macOS's
/// ⌃⌥⌘) so they never hijack plain typing — and deliberately avoid the Win key, since
/// Win+1…9 is reserved by the shell. Messages arrive on a hidden message-only window
/// pumped on the UI thread, so callbacks can touch the UI directly.
/// </summary>
public sealed class HotKeyCenter : IDisposable
{
    private const uint Modifiers = NativeMethods.MOD_CONTROL | NativeMethods.MOD_ALT
                                 | NativeMethods.MOD_SHIFT | NativeMethods.MOD_NOREPEAT;

    private readonly Dictionary<int, Action> _handlers = new();
    private MessageWindow? _window;
    private int _nextId = 1;

    /// <summary>Creates the message-only window. Call once before binding keys.</summary>
    public void Install() => _window = new MessageWindow(Dispatch);

    /// <summary>Binds Ctrl+Alt+Shift + <paramref name="virtualKey"/> (a <c>VK_*</c> code) to a callback.</summary>
    public void Bind(uint virtualKey, Action handler)
    {
        if (_window is null) return;
        int id = _nextId++;
        if (NativeMethods.RegisterHotKey(_window.Handle, id, Modifiers, virtualKey))
            _handlers[id] = handler;
    }

    private void Dispatch(int id)
    {
        if (_handlers.TryGetValue(id, out var handler))
            handler();   // already on the UI thread
    }

    public void Dispose()
    {
        if (_window is null) return;
        foreach (var id in _handlers.Keys)
            NativeMethods.UnregisterHotKey(_window.Handle, id);
        _handlers.Clear();
        _window.DestroyHandle();
        _window = null;
    }

    /// <summary>An invisible message-only window that turns <c>WM_HOTKEY</c> into callbacks.</summary>
    private sealed class MessageWindow : NativeWindow
    {
        private readonly Action<int> _onHotKey;

        public MessageWindow(Action<int> onHotKey)
        {
            _onHotKey = onHotKey;
            CreateHandle(new CreateParams { Parent = NativeMethods.HWND_MESSAGE });
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == NativeMethods.WM_HOTKEY)
                _onHotKey((int)m.WParam);
            base.WndProc(ref m);
        }
    }
}
