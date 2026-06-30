#pragma once

#include <windows.h>
#include <winrt/Microsoft.UI.Xaml.h>

namespace glassface
{
    // Helpers for turning a plain WinUI 3 Window into a borderless, top-most, click-through
    // overlay that exactly covers one physical-pixel monitor rectangle. The Windows analog
    // of the macOS borderless NSWindow at .screenSaver level with ignoresMouseEvents.

    HWND GetWindowHandle(winrt::Microsoft::UI::Xaml::Window const& window);

    void ConfigureOverlayWindow(winrt::Microsoft::UI::Xaml::Window const& window, RECT const& bounds);
}
