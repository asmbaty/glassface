#include "pch.h"
#include "ScreenOverlay.h"
#include "OverlayWindow.h"

using namespace winrt;
using namespace winrt::Microsoft::UI::Xaml;
using namespace winrt::Microsoft::UI::Xaml::Controls;
using namespace winrt::Microsoft::UI::Xaml::Media;
using namespace winrt::Microsoft::UI::Xaml::Media::Imaging;

namespace glassface
{
    ScreenOverlay::ScreenOverlay(RECT const& bounds, float opacity, SoftwareBitmapSource const& source)
    {
        m_window = Window();

        Grid root;
        root.Background(SolidColorBrush(winrt::Microsoft::UI::Colors::Transparent()));

        m_image = Image();
        m_image.Stretch(Stretch::UniformToFill);          // ≈ AVLayerVideoGravityResizeAspectFill
        m_image.Opacity(opacity);
        m_image.Source(source);
        m_image.RenderTransformOrigin(winrt::Windows::Foundation::Point{ 0.5f, 0.5f });

        ScaleTransform flip;                              // mirror (selfie view)
        flip.ScaleX(-1.0);
        flip.ScaleY(1.0);
        m_image.RenderTransform(flip);

        root.Children().Append(m_image);
        m_window.Content(root);

        ConfigureOverlayWindow(m_window, bounds);
    }

    void ScreenOverlay::Present()
    {
        m_window.Activate();
    }

    void ScreenOverlay::SetOpacity(float value)
    {
        m_image.Opacity(value);
    }
}
