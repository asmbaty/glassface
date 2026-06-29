using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace GlassFace;

/// <summary>
/// One display's overlay: the transparent window plus the mirrored camera image drawn into
/// it. The image is shown at reduced opacity (the "glass" effect) and horizontally flipped
/// for a natural selfie view, matching the macOS preview layer's mirroring.
/// </summary>
public sealed class ScreenOverlay
{
    private readonly OverlayWindow _window;
    private readonly Image _image;

    public ScreenOverlay(NativeMethods.RECT bounds, float opacity)
    {
        _window = new OverlayWindow(bounds);

        _image = new Image
        {
            Stretch = Stretch.UniformToFill,            // ≈ AVLayerVideoGravityResizeAspectFill
            Opacity = opacity,
            RenderTransformOrigin = new Point(0.5, 0.5),
            RenderTransform = new ScaleTransform(-1, 1)  // mirror (selfie view)
        };
        RenderOptions.SetBitmapScalingMode(_image, BitmapScalingMode.LowQuality); // fast preview scaling

        var root = new Grid { Background = Brushes.Transparent };
        root.Children.Add(_image);
        _window.Content = root;
    }

    public void Present() => _window.Show();

    public void SetOpacity(float value) => _image.Opacity = value;

    public void SetSource(ImageSource source) => _image.Source = source;
}
