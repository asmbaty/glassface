#include "pch.h"
#include "OverlayCoordinator.h"
#include "NativeHelpers.h"
#include <algorithm>

using namespace winrt;
using namespace winrt::Windows::Graphics::Imaging;
using namespace winrt::Microsoft::UI::Dispatching;
using namespace winrt::Microsoft::UI::Xaml::Media::Imaging;

namespace glassface
{
    OverlayCoordinator::OverlayCoordinator(AppConfiguration const& config)
        : m_opacity(config.defaultOpacity)
    {
    }

    void OverlayCoordinator::BuildOverlays()
    {
        m_dispatcher = DispatcherQueue::GetForCurrentThread();
        m_source = SoftwareBitmapSource();

        for (auto const& bounds : EnumerateMonitors())
            m_overlays.push_back(std::make_unique<ScreenOverlay>(bounds, m_opacity, m_source));

        for (auto const& overlay : m_overlays)
            overlay->Present();
    }

    float OverlayCoordinator::SetOpacity(float value)
    {
        m_opacity = std::clamp(value, 0.0f, 1.0f);
        for (auto const& overlay : m_overlays)
            overlay->SetOpacity(m_opacity);
        return m_opacity;
    }

    void OverlayCoordinator::Consume(SoftwareBitmap const& bitmap)
    {
        if (!m_dispatcher) return;

        // Drop frames while one is still being uploaded, so we never queue up a backlog.
        bool expected = false;
        if (!m_busy.compare_exchange_strong(expected, true)) return;

        SoftwareBitmap frame = bitmap;
        bool queued = m_dispatcher.TryEnqueue([this, frame]() { RenderOnUi(frame); });
        if (!queued) m_busy.store(false);
    }

    fire_and_forget OverlayCoordinator::RenderOnUi(SoftwareBitmap bitmap)
    {
        // Runs on the UI thread (enqueued via the dispatcher); SetBitmapAsync resumes here too.
        try { co_await m_source.SetBitmapAsync(bitmap); }
        catch (...) {}
        m_busy.store(false);
    }
}
