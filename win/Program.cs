using System;
using System.Windows;

namespace GlassFace;

/// <summary>
/// Entry point. All behavior lives in the <c>Sources/</c> types; this file just stands
/// the WPF application up and hands control to the composition root (<see cref="AppCoordinator"/>).
///
/// The app has no main window — it lives in the system tray — so the shutdown mode is
/// explicit and the coordinator drives the whole lifetime.
/// </summary>
public sealed class App : Application
{
    private AppCoordinator? _coordinator;

    [STAThread]
    public static void Main()
    {
        var app = new App { ShutdownMode = ShutdownMode.OnExplicitShutdown };
        app.Startup += app.OnStartup;
        app.Run();
    }

    private void OnStartup(object sender, StartupEventArgs e)
    {
        _coordinator = new AppCoordinator();   // retained for the lifetime of the process
        _coordinator.Start();
    }
}
