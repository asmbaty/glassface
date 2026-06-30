#include "pch.h"
#include "OverlayWindow.h"
#include "NativeHelpers.h"

using namespace winrt;
using namespace winrt::Microsoft::UI::Xaml;
using namespace winrt::Microsoft::UI::Windowing;

namespace glassface
{
    HWND GetWindowHandle(Window const& window)
    {
        HWND hwnd{};
        if (auto native = window.try_as<::IWindowNative>())
            native->get_WindowHandle(&hwnd);
        return hwnd;
    }

    void ConfigureOverlayWindow(Window const& window, RECT const& bounds)
    {
        auto appWindow = window.AppWindow();

        // Borderless, always-on-top, non-interactive chrome.
        auto presenter = OverlappedPresenter::Create();
        presenter.SetBorderAndTitleBar(false, false);
        presenter.IsAlwaysOnTop(true);
        presenter.IsResizable(false);
        presenter.IsMaximizable(false);
        presenter.IsMinimizable(false);
        appWindow.SetPresenter(presenter);

        // Cover the monitor exactly, in physical pixels.
        appWindow.MoveAndResize(winrt::Windows::Graphics::RectInt32{
            bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top });

        // Pass clicks/keys through to whatever is underneath.
        MakeClickThrough(GetWindowHandle(window));
    }
}
