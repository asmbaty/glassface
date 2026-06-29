using System;
using System.Threading.Tasks;
using System.Windows;

namespace GlassFace;

/// <summary>
/// Composition root. Builds the collaborators, wires them together, and orchestrates the
/// cross-cutting flows (camera setup, opacity, hot keys). It holds no rendering or capture
/// logic itself — each of those lives in its own single-responsibility type.
/// </summary>
public sealed class AppCoordinator : IStatusMenuDelegate
{
    // Virtual-key codes (VK_*) used for the global hot keys.
    private const uint VK_Q = 0x51;
    private const uint VK_OEM_PLUS = 0xBB;   // '=' / '+' on the main keyboard
    private const uint VK_OEM_MINUS = 0xBD;  // '-' / '_'

    private readonly AppConfiguration _config = new();
    private readonly CameraService _camera = new();
    private readonly OverlayCoordinator _overlay;
    private readonly HotKeyCenter _hotKeys = new();
    private readonly StatusMenuController _menu = new();

    public AppCoordinator()
    {
        _overlay = new OverlayCoordinator(_config);
        _camera.FrameConsumer = _overlay;
        _menu.Delegate = this;
    }

    // MARK: App lifecycle

    public void Start()
    {
        _menu.Install();
        _menu.UpdateOpacity(_overlay.Opacity);
        _overlay.BuildOverlays();
        ConfigureHotKeys();

        _ = ConfigureCameraAsync();   // fire-and-forget; failures surface as alerts
    }

    private async Task ConfigureCameraAsync()
    {
        try
        {
            await _camera.ConfigureAsync();
        }
        catch (UnauthorizedAccessException)
        {
            AlertPresenter.CameraPermissionDenied();
            return;
        }
        catch (Exception)
        {
            AlertPresenter.NoCamera();
            return;
        }

        await _camera.StartAsync();
    }

    // MARK: Opacity orchestration

    /// <summary>Single funnel for every opacity change, wherever it originates.</summary>
    private void SetOpacity(float value)
    {
        float applied = _overlay.SetOpacity(value);
        _menu.UpdateOpacity(applied);
        _ = _camera.SetRunningAsync(applied > 0);   // camera genuinely off at 0% (privacy light out)
    }

    private void IncreaseOpacity() => SetOpacity(_overlay.Opacity + _config.OpacityStep);
    private void DecreaseOpacity() => SetOpacity(_overlay.Opacity - _config.OpacityStep);

    // MARK: Hot keys

    private void ConfigureHotKeys()
    {
        _hotKeys.Install();
        _hotKeys.Bind(VK_Q, Quit);
        _hotKeys.Bind(VK_OEM_PLUS, IncreaseOpacity);
        _hotKeys.Bind(VK_OEM_MINUS, DecreaseOpacity);

        // Number keys jump straight to a level: 1…9 → 10%…90%, 0 → 100%.
        for (uint digit = 1; digit <= 9; digit++)
        {
            float level = digit / 10f;
            _hotKeys.Bind(0x30u + digit, () => SetOpacity(level));   // VK_1 = 0x31 … VK_9 = 0x39
        }
        _hotKeys.Bind(0x30, () => SetOpacity(1.0f));                 // VK_0 = 0x30
    }

    private void Quit()
    {
        _hotKeys.Dispose();
        _menu.Dispose();
        Application.Current?.Shutdown();
    }

    // MARK: Tray menu actions

    public void StatusMenuDidRequestIncreaseOpacity() => IncreaseOpacity();
    public void StatusMenuDidRequestDecreaseOpacity() => DecreaseOpacity();
    public void StatusMenuDidRequestQuit() => Quit();
}
