#pragma once

#include <vector>
#include <memory>
#include <atomic>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Xaml.Media.Imaging.h>

#include "AppConfiguration.h"
#include "ScreenOverlay.h"

namespace glassface
{
    // Owns every display's overlay and renders camera frames into them. Camera frames arrive
    // off the UI thread; this copies the latest one into a shared SoftwareBitmapSource that
    // all the per-screen images display, and applies opacity across all of them. It renders;
    // it does not manage the camera session lifecycle (that's the coordinator's job).
    class OverlayCoordinator
    {
    public:
        explicit OverlayCoordinator(AppConfiguration const& config);

        float Opacity() const { return m_opacity; }

        // Creates one overlay window per connected display and shows them. Call on the UI thread.
        void BuildOverlays();

        // Clamps, applies, and returns the resulting opacity.
        float SetOpacity(float value);

        // Frame sink for CameraService — called off the UI thread.
        void Consume(winrt::Windows::Graphics::Imaging::SoftwareBitmap const& bitmap);

    private:
        winrt::fire_and_forget RenderOnUi(winrt::Windows::Graphics::Imaging::SoftwareBitmap bitmap);

        std::vector<std::unique_ptr<ScreenOverlay>> m_overlays;
        winrt::Microsoft::UI::Xaml::Media::Imaging::SoftwareBitmapSource m_source{ nullptr };
        winrt::Microsoft::UI::Dispatching::DispatcherQueue m_dispatcher{ nullptr };
        std::atomic<bool> m_busy{ false };
        float m_opacity;
    };
}
