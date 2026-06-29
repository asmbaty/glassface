using System;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;

namespace GlassFace;

/// <summary>
/// A borderless, per-pixel-transparent, click-through window pinned across one display.
/// <c>WS_EX_TRANSPARENT</c> is what keeps the PC fully usable underneath the overlay — the
/// Windows analog of macOS's <c>ignoresMouseEvents</c>. It is placed with physical monitor
/// pixels (via <c>SetWindowPos</c>) so it covers the whole display under any DPI scale.
/// </summary>
public sealed class OverlayWindow : Window
{
    private readonly NativeMethods.RECT _bounds;

    public OverlayWindow(NativeMethods.RECT bounds)
    {
        _bounds = bounds;

        Title = "GlassFace";
        WindowStyle = WindowStyle.None;
        AllowsTransparency = true;           // layered window with per-pixel alpha
        Background = Brushes.Transparent;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        ShowActivated = false;               // never grab focus on show
        Topmost = true;                      // floats above normal windows (≈ macOS .screenSaver)
        WindowStartupLocation = WindowStartupLocation.Manual;
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);

        var hwnd = new WindowInteropHelper(this).Handle;

        long ex = NativeMethods.GetWindowLongPtr(hwnd, NativeMethods.GWL_EXSTYLE).ToInt64();
        ex |= NativeMethods.WS_EX_TRANSPARENT | NativeMethods.WS_EX_TOOLWINDOW
            | NativeMethods.WS_EX_NOACTIVATE | NativeMethods.WS_EX_LAYERED;
        NativeMethods.SetWindowLongPtr(hwnd, NativeMethods.GWL_EXSTYLE, new IntPtr(ex));

        // Cover the monitor exactly, in physical pixels (bypasses WPF DIP scaling).
        NativeMethods.SetWindowPos(hwnd, NativeMethods.HWND_TOPMOST,
            _bounds.Left, _bounds.Top, _bounds.Width, _bounds.Height,
            NativeMethods.SWP_NOACTIVATE | NativeMethods.SWP_SHOWWINDOW);
    }
}
