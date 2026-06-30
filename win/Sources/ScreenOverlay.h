#pragma once

#include <windows.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Media.Imaging.h>

namespace glassface
{
    // One display's overlay: the transparent window plus the mirrored camera image drawn
    // into it. The image is shown at reduced opacity (the "glass" effect) and horizontally
    // flipped for a natural selfie view, matching the macOS preview layer's mirroring.
    class ScreenOverlay
    {
    public:
        ScreenOverlay(RECT const& bounds, float opacity,
                      winrt::Microsoft::UI::Xaml::Media::Imaging::SoftwareBitmapSource const& source);

        void Present();
        void SetOpacity(float value);

    private:
        winrt::Microsoft::UI::Xaml::Window m_window{ nullptr };
        winrt::Microsoft::UI::Xaml::Controls::Image m_image{ nullptr };
    };
}
