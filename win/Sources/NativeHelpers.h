#pragma once

#include <windows.h>
#include <vector>

namespace glassface
{
    // The thin layer of Win32 the overlay needs: enumerating displays and making a window
    // transparent to mouse/keyboard input. Centralized so the rest stays free of interop noise.

    // Physical-pixel bounds of every connected display (full monitor, incl. taskbar).
    std::vector<RECT> EnumerateMonitors();

    // Apply the extended styles that make an overlay window click-through and unobtrusive:
    // WS_EX_TRANSPARENT (clicks/keys pass through), WS_EX_LAYERED (per-pixel alpha),
    // WS_EX_TOOLWINDOW (out of Alt-Tab), WS_EX_NOACTIVATE (never steals focus).
    void MakeClickThrough(HWND hwnd);
}
