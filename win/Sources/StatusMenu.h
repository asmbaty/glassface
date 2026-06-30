#pragma once

#include <windows.h>
#include <shellapi.h>
#include <functional>

namespace glassface
{
    // Owns the system-tray icon and its right-click menu, forwarding clicks to callbacks.
    // The Windows analog of the macOS menu-bar status item. WinUI 3 has no tray support, so
    // this is built directly on Shell_NotifyIcon + a Win32 popup menu, driven by a hidden
    // window pumped on the UI thread.
    class StatusMenu
    {
    public:
        std::function<void()> onIncrease;
        std::function<void()> onDecrease;
        std::function<void()> onQuit;

        ~StatusMenu();

        void Install();
        void UpdateOpacity(float opacity);

    private:
        static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
        void ShowMenu();

        HWND m_window{ nullptr };
        HICON m_icon{ nullptr };
        NOTIFYICONDATAW m_nid{};
        int m_opacityPercent{ 0 };
    };
}
