using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace GlassFace;

/// <summary>
/// The thin layer of Win32 P/Invoke the app needs: extended window styles (to make the
/// overlay click-through), monitor enumeration (one overlay per display), global hot-key
/// registration, and the message-only window that receives <c>WM_HOTKEY</c>.
/// Centralized here so the rest of the code stays free of interop noise.
/// </summary>
internal static class NativeMethods
{
    // Extended window styles.
    internal const int GWL_EXSTYLE = -20;
    internal const long WS_EX_TRANSPARENT = 0x00000020; // clicks/keys pass through to apps below
    internal const long WS_EX_TOOLWINDOW  = 0x00000080; // keep it out of Alt-Tab
    internal const long WS_EX_LAYERED     = 0x00080000; // per-pixel alpha (WPF sets this too)
    internal const long WS_EX_NOACTIVATE  = 0x08000000; // never steal focus

    // SetWindowPos.
    internal static readonly IntPtr HWND_TOPMOST = new(-1);
    internal const uint SWP_NOACTIVATE = 0x0010;
    internal const uint SWP_SHOWWINDOW = 0x0040;

    // Hot keys.
    internal const uint MOD_ALT      = 0x0001;
    internal const uint MOD_CONTROL  = 0x0002;
    internal const uint MOD_SHIFT    = 0x0004;
    internal const uint MOD_NOREPEAT = 0x4000;
    internal const int WM_HOTKEY = 0x0312;

    // Parent handle for a message-only window (receives posted messages, never shown).
    internal static readonly IntPtr HWND_MESSAGE = new(-3);

    [StructLayout(LayoutKind.Sequential)]
    internal struct RECT
    {
        public int Left, Top, Right, Bottom;
        public readonly int Width => Right - Left;
        public readonly int Height => Bottom - Top;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct MONITORINFO
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
    }

    [DllImport("user32.dll", SetLastError = true, EntryPoint = "GetWindowLongPtrW")]
    internal static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true, EntryPoint = "SetWindowLongPtrW")]
    internal static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    private delegate bool MonitorEnumDelegate(IntPtr hMonitor, IntPtr hdc, ref RECT rect, IntPtr data);

    [DllImport("user32.dll")]
    private static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorEnumDelegate callback, IntPtr data);

    [DllImport("user32.dll")]
    private static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO info);

    /// <summary>Physical-pixel bounds of every connected display (full monitor, incl. taskbar).</summary>
    internal static List<RECT> EnumerateMonitors()
    {
        var result = new List<RECT>();
        bool Callback(IntPtr hMon, IntPtr hdc, ref RECT lprc, IntPtr data)
        {
            var info = new MONITORINFO { cbSize = Marshal.SizeOf<MONITORINFO>() };
            if (GetMonitorInfo(hMon, ref info))
                result.Add(info.rcMonitor);
            return true;
        }
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, Callback, IntPtr.Zero);
        return result;
    }
}
