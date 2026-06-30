#include "pch.h"
#include "CameraService.h"

using namespace winrt;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Foundation::Collections;
using namespace winrt::Windows::Devices::Enumeration;
using namespace winrt::Windows::Graphics::Imaging;
using namespace winrt::Windows::Media::Capture;
using namespace winrt::Windows::Media::Capture::Frames;
using namespace winrt::Windows::Media::MediaProperties;

namespace glassface
{
    IAsyncAction CameraService::ConfigureAsync()
    {
        // Prefer the front-facing (selfie) camera; fall back to any available camera.
        auto devices = co_await DeviceInformation::FindAllAsync(DeviceClass::VideoCapture);
        if (devices.Size() == 0)
            throw hresult_error(E_FAIL, L"No camera device found.");

        DeviceInformation chosen{ nullptr };
        for (auto const& device : devices)
        {
            auto enclosure = device.EnclosureLocation();
            if (enclosure && enclosure.Panel() == Panel::Front) { chosen = device; break; }
        }
        if (!chosen) chosen = devices.GetAt(0);

        auto settings = MediaCaptureInitializationSettings();
        settings.VideoDeviceId(chosen.Id());
        settings.StreamingCaptureMode(StreamingCaptureMode::Video);
        settings.MemoryPreference(MediaCaptureMemoryPreference::Cpu);   // CPU frames -> easy to display
        settings.SharingMode(MediaCaptureSharingMode::ExclusiveControl);

        m_capture = MediaCapture();
        co_await m_capture.InitializeAsync(settings);   // throws E_ACCESSDENIED if user declined

        MediaFrameSource source{ nullptr };
        for (auto const& kv : m_capture.FrameSources())
        {
            if (kv.Value().Info().SourceKind() == MediaFrameSourceKind::Color)
            {
                source = kv.Value();
                break;
            }
        }
        if (!source)
            throw hresult_error(E_FAIL, L"No color camera frame source available.");

        m_reader = co_await m_capture.CreateFrameReaderAsync(source, MediaEncodingSubtypes::Bgra8());
        m_reader.AcquisitionMode(MediaFrameReaderAcquisitionMode::Realtime);   // drop late frames
        m_frameToken = m_reader.FrameArrived({ this, &CameraService::OnFrameArrived });
    }

    IAsyncAction CameraService::StartAsync()
    {
        co_await SetRunningAsync(true);
    }

    IAsyncAction CameraService::SetRunningAsync(bool running)
    {
        if (!m_reader) co_return;
        if (running && !m_running)
        {
            co_await m_reader.StartAsync();
            m_running = true;
        }
        else if (!running && m_running)
        {
            co_await m_reader.StopAsync();
            m_running = false;
        }
    }

    void CameraService::OnFrameArrived(MediaFrameReader const& sender, MediaFrameArrivedEventArgs const&)
    {
        auto frame = sender.TryAcquireLatestFrame();
        if (!frame) return;
        auto videoFrame = frame.VideoMediaFrame();
        if (!videoFrame) return;
        auto bitmap = videoFrame.SoftwareBitmap();
        if (!bitmap) return;

        // SoftwareBitmapSource wants BGRA8 with premultiplied alpha.
        if (bitmap.BitmapPixelFormat() != BitmapPixelFormat::Bgra8 ||
            bitmap.BitmapAlphaMode() != BitmapAlphaMode::Premultiplied)
        {
            bitmap = SoftwareBitmap::Convert(bitmap, BitmapPixelFormat::Bgra8, BitmapAlphaMode::Premultiplied);
        }

        if (frameConsumer)
            frameConsumer(bitmap);
    }
}
