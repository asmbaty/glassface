#pragma once

#include <functional>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Capture.h>
#include <winrt/Windows.Media.Capture.Frames.h>

namespace glassface
{
    // Owns the WinRT MediaCapture graph: device discovery, the frame reader, and
    // starting/stopping capture. Its single responsibility is supplying camera frames as
    // BGRA8 (premultiplied) SoftwareBitmaps to its consumer. Knows nothing about windows.
    class CameraService
    {
    public:
        // Called on a capture thread (off the UI thread) with a fresh, ready-to-display
        // BGRA8/premultiplied SoftwareBitmap. The consumer marshals to the UI itself.
        std::function<void(winrt::Windows::Graphics::Imaging::SoftwareBitmap)> frameConsumer;

        // Builds the capture graph. Throws hresult_access_denied if the user denied camera
        // access, or hresult_error if no usable camera is available.
        winrt::Windows::Foundation::IAsyncAction ConfigureAsync();

        winrt::Windows::Foundation::IAsyncAction StartAsync();

        // Starting/stopping the reader; stopping turns the camera (and its privacy light) off.
        winrt::Windows::Foundation::IAsyncAction SetRunningAsync(bool running);

    private:
        void OnFrameArrived(winrt::Windows::Media::Capture::Frames::MediaFrameReader const& sender,
                            winrt::Windows::Media::Capture::Frames::MediaFrameArrivedEventArgs const& args);

        winrt::Windows::Media::Capture::MediaCapture m_capture{ nullptr };
        winrt::Windows::Media::Capture::Frames::MediaFrameReader m_reader{ nullptr };
        winrt::event_token m_frameToken{};
        bool m_running{ false };
    };
}
