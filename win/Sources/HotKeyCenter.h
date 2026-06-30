#pragma once

#include <windows.h>
#include <functional>
#include <unordered_map>

namespace glassface
{
    // Registers global hot keys via Win32 RegisterHotKey and routes each to a callback.
    // All bindings use Ctrl+Alt+Shift (the analog of macOS's ⌃⌥⌘) so they never hijack
    // plain typing — and deliberately avoid the Win key, since Win+1…9 is reserved by the
    // shell. WM_HOTKEY arrives on a hidden message-only window pumped on the UI thread, so
    // callbacks may touch the UI directly.
    class HotKeyCenter
    {
    public:
        ~HotKeyCenter();

        // Creates the message-only window. Call once (on the UI thread) before binding keys.
        void Install();

        // Binds Ctrl+Alt+Shift + virtualKey (a VK_* code) to handler.
        void Bind(UINT virtualKey, std::function<void()> handler);

    private:
        static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

        HWND m_window{ nullptr };
        std::unordered_map<int, std::function<void()>> m_handlers;
        int m_nextId{ 1 };
    };
}
