using System.Windows;

namespace GlassFace;

/// <summary>
/// Presents a fatal error as a modal dialog, then terminates. One job, no state.
/// </summary>
internal static class AlertPresenter
{
    internal static void CameraPermissionDenied() =>
        Show("Camera access denied",
            "Enable camera access for GlassFace in Settings → Privacy & security → Camera, then relaunch.");

    internal static void NoCamera() =>
        Show("No camera found", "GlassFace couldn't find a usable camera on this PC.");

    private static void Show(string title, string message)
    {
        MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Error);
        Application.Current?.Shutdown();
    }
}
