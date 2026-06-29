using System;
using WinForms = System.Windows.Forms;

namespace GlassFace;

/// <summary>
/// Actions the tray menu can request. The controller depends on this narrow protocol rather
/// than the concrete app coordinator (Interface Segregation / Dependency Inversion).
/// </summary>
public interface IStatusMenuDelegate
{
    void StatusMenuDidRequestIncreaseOpacity();
    void StatusMenuDidRequestDecreaseOpacity();
    void StatusMenuDidRequestQuit();
}

/// <summary>
/// Builds and owns the system-tray icon and its menu, forwarding clicks to its delegate.
/// The Windows analog of the macOS menu-bar status item.
/// </summary>
public sealed class StatusMenuController : IDisposable
{
    public IStatusMenuDelegate? Delegate { get; set; }

    private WinForms.NotifyIcon? _icon;
    private WinForms.ToolStripMenuItem? _opacityItem;

    public void Install()
    {
        _icon = new WinForms.NotifyIcon
        {
            Icon = GhostImageRenderer.TrayIcon(),
            Text = "GlassFace",
            Visible = true,
            ContextMenuStrip = BuildMenu()
        };
    }

    public void UpdateOpacity(float opacity)
    {
        if (_opacityItem is not null)
            _opacityItem.Text = $"Opacity: {(int)Math.Round(opacity * 100)}%";
    }

    private WinForms.ContextMenuStrip BuildMenu()
    {
        var menu = new WinForms.ContextMenuStrip();

        _opacityItem = new WinForms.ToolStripMenuItem("Opacity: —") { Enabled = false };
        menu.Items.Add(_opacityItem);

        menu.Items.Add(new WinForms.ToolStripSeparator());
        menu.Items.Add(MakeItem("Increase Opacity\tCtrl+Alt+Shift +",
            (_, _) => Delegate?.StatusMenuDidRequestIncreaseOpacity()));
        menu.Items.Add(MakeItem("Decrease Opacity\tCtrl+Alt+Shift -",
            (_, _) => Delegate?.StatusMenuDidRequestDecreaseOpacity()));

        menu.Items.Add(new WinForms.ToolStripMenuItem("Set Opacity: Ctrl+Alt+Shift 1–9, 0 = 100%") { Enabled = false });

        menu.Items.Add(new WinForms.ToolStripSeparator());
        menu.Items.Add(MakeItem("Quit GlassFace\tCtrl+Alt+Shift Q",
            (_, _) => Delegate?.StatusMenuDidRequestQuit()));

        return menu;
    }

    private static WinForms.ToolStripMenuItem MakeItem(string title, EventHandler onClick)
    {
        var item = new WinForms.ToolStripMenuItem(title);
        item.Click += onClick;
        return item;
    }

    public void Dispose()
    {
        if (_icon is null) return;
        _icon.Visible = false;
        _icon.Dispose();
        _icon = null;
    }
}
