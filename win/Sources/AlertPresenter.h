#pragma once

#include <windows.h>
#include <winrt/Microsoft.UI.Xaml.h>

namespace glassface
{
    // Presents a fatal error as a modal dialog, then terminates. One job, no state.
    // Call on the UI thread (Application::Exit must run there).
    struct AlertPresenter
    {
        static void CameraPermissionDenied()
        {
            Show(L"Camera access denied",
                 L"Enable camera access for GlassFace in Settings > Privacy & security > Camera, then relaunch.");
        }

        static void NoCamera()
        {
            Show(L"No camera found", L"GlassFace couldn't find a usable camera on this PC.");
        }

    private:
        static void Show(const wchar_t* title, const wchar_t* message)
        {
            MessageBoxW(nullptr, message, title, MB_OK | MB_ICONERROR | MB_TOPMOST);
            if (auto app = winrt::Microsoft::UI::Xaml::Application::Current())
                app.Exit();
        }
    };
}
