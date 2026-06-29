using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace GlassFace;

/// <summary>
/// Owns every display's overlay and renders camera frames into them. As the camera's
/// <see cref="IFrameConsumer"/>, it copies each frame into one shared
/// <see cref="WriteableBitmap"/> that all the per-screen images display, and applies opacity
/// across all of them. It renders; it does not manage the camera session lifecycle
/// (that's the coordinator's job).
/// </summary>
public sealed class OverlayCoordinator : IFrameConsumer
{
    public float Opacity { get; private set; }

    private readonly List<ScreenOverlay> _overlays = new();
    private WriteableBitmap? _preview;

    public OverlayCoordinator(AppConfiguration config)
    {
        Opacity = config.DefaultOpacity;
    }

    /// <summary>Creates one overlay window per connected display and shows them.</summary>
    public void BuildOverlays()
    {
        foreach (var bounds in NativeMethods.EnumerateMonitors())
            _overlays.Add(new ScreenOverlay(bounds, Opacity));
        foreach (var overlay in _overlays)
            overlay.Present();
    }

    /// <summary>Clamps, applies, and returns the resulting opacity.</summary>
    public float SetOpacity(float value)
    {
        Opacity = Math.Clamp(value, 0f, 1f);
        foreach (var overlay in _overlays)
            overlay.SetOpacity(Opacity);
        return Opacity;
    }

    // MARK: IFrameConsumer — called off the UI thread by CameraService.

    public void Consume(CameraFrame frame)
    {
        var dispatcher = Application.Current?.Dispatcher;
        if (dispatcher is null || dispatcher.HasShutdownStarted) return;

        // Synchronous so the camera's reusable buffer is safe to overwrite once we return.
        try { dispatcher.Invoke(() => Render(frame)); }
        catch (System.Threading.Tasks.TaskCanceledException) { /* shutting down */ }
    }

    private void Render(CameraFrame frame)
    {
        if (_preview is null || _preview.PixelWidth != frame.Width || _preview.PixelHeight != frame.Height)
        {
            _preview = new WriteableBitmap(frame.Width, frame.Height, 96, 96, PixelFormats.Bgr32, null);
            foreach (var overlay in _overlays)
                overlay.SetSource(_preview);
        }

        _preview.WritePixels(new Int32Rect(0, 0, frame.Width, frame.Height),
            frame.Bgra, frame.Width * 4, 0);
    }
}
