#include "pch.h"
#include "NativeHelpers.h"

namespace glassface
{
    static BOOL CALLBACK MonitorProc(HMONITOR monitor, HDC, LPRECT, LPARAM data)
    {
        MONITORINFO info{};
        info.cbSize = sizeof(info);
        if (GetMonitorInfoW(monitor, &info))
            reinterpret_cast<std::vector<RECT>*>(data)->push_back(info.rcMonitor);
        return TRUE;
    }

    std::vector<RECT> EnumerateMonitors()
    {
        std::vector<RECT> monitors;
        EnumDisplayMonitors(nullptr, nullptr, MonitorProc, reinterpret_cast<LPARAM>(&monitors));
        return monitors;
    }

    void MakeClickThrough(HWND hwnd)
    {
        LONG_PTR ex = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
        ex |= WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
        SetWindowLongPtrW(hwnd, GWL_EXSTYLE, ex);

        // A layered window stays invisible until its alpha is established; treat the whole
        // surface as fully opaque per-pixel so XAML's own per-pixel alpha drives visibility.
        SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
    }
}
