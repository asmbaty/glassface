# GlassFace for Windows

A tiny native Windows app that shows your **front camera feed as a semi-transparent,
full-screen overlay** — while you keep using your PC completely normally. The overlay
floats above everything and **passes all clicks and keystrokes through** to the apps
underneath.

This is a Windows port of the macOS [GlassFace](../README.md). The macOS sources are
untouched; everything here lives under `win/`.

> **Note:** Unlike the macOS build, this Windows version has **no heart / hand-gesture
> detection** — Windows has no in-box hand-pose API and the project keeps a zero
> third-party-dependency policy. The overlay, tray, hot keys, camera, and multi-monitor
> support are all present.

## Requirements
- Windows 10 (build 19041 / 20H1) or Windows 11
- [.NET 8 SDK](https://dotnet.microsoft.com/download) — no Visual Studio required

## Build
```powershell
./build.ps1
```
or
```cmd
build.cmd
```
This compiles everything under `Sources/` (plus `Program.cs`) with the .NET SDK. No
project/solution file beyond `GlassFace.csproj` is needed.

## Run
```powershell
dotnet run --project GlassFace.csproj -c Release
```
On first launch Windows asks for **camera permission** — approve it (Settings → Privacy &
security → Camera). The transparent feed then covers your whole screen.

To produce a standalone executable:
```powershell
dotnet publish GlassFace.csproj -c Release -r win-x64 --self-contained false
```

## Tray icon & hotkeys
GlassFace lives in the **system tray** (ghost icon, bottom-right). Click it for a menu
showing the current opacity, with Increase / Decrease / Quit. Global hotkeys work from any
app and use **Ctrl+Alt+Shift** (the analog of macOS's ⌃⌥⌘; the Win key is avoided because
Win+1…9 is reserved by Windows):

| Action | Hotkey |
|--------|--------|
| Increase opacity | **Ctrl+Alt+Shift +** |
| Decrease opacity | **Ctrl+Alt+Shift -** |
| Set opacity 10%–90% | **Ctrl+Alt+Shift 1** … **Ctrl+Alt+Shift 9** |
| Set opacity 100% | **Ctrl+Alt+Shift 0** |
| Quit | **Ctrl+Alt+Shift Q** |

Opacity changes by 10% per press, clamped to 0–100%. At 0% the camera is genuinely stopped
(privacy light off).

## Customize
Almost everything tunable lives in **`Sources/AppConfiguration.cs`**: `DefaultOpacity`
(`0.0` = invisible, `1.0` = opaque; default `0.35`) and `OpacityStep` (hotkey increment).
The camera defaults to the **front-facing** camera and the feed is **mirrored** (selfie
view) — see `CameraService.FrontCameraAsync()` and the `ScaleTransform` in
`ScreenOverlay.cs`. An overlay is created for **every connected display** automatically.

## How it works
The code mirrors the macOS app's small single-responsibility types, wired together by
`AppCoordinator` (the composition root); `Program.cs` is just the entry point.

| Concern | Type(s) |
|---------|---------|
| Configuration (all tunables) | `AppConfiguration` |
| Camera capture & frame delivery | `CameraService` (`IFrameConsumer`, `CameraFrame`) |
| On-screen overlay | `OverlayCoordinator`, `ScreenOverlay`, `OverlayWindow` |
| Global hot keys (Win32) | `HotKeyCenter` |
| System tray | `StatusMenuController`, `GhostImageRenderer` |
| Errors | `AlertPresenter` |
| Win32 interop | `NativeMethods` |
| Wiring / orchestration | `AppCoordinator` |

Under the hood: a **WPF** borderless `Window` per display (`AllowsTransparency`, `Topmost`,
plus the `WS_EX_TRANSPARENT` extended style — the key to staying click-through); in-box
**WinRT Media Capture** (`MediaCapture` → `MediaFrameReader`) feeding a shared
`WriteableBitmap` drawn at reduced opacity and mirrored; **Win32** `RegisterHotKey` for
global shortcuts; and a **WinForms** `NotifyIcon` for the tray.

### Why WPF (and not WinUI 3)?
WPF gives a true per-pixel-transparent, click-through, always-on-top window with arbitrary
content out of the box — exactly what a full-screen camera overlay needs — and it runs on
modern .NET 8. WinUI 3's windowing model makes layered transparency and per-monitor
borderless overlays considerably harder, so WPF is the better fit here.

## Notes
- The overlay sits above normal windows. It does not appear over another app's exclusive
  full-screen mode; use it on the normal desktop.
- Virtual desktops: the overlay shows on the current desktop (Windows doesn't expose a
  documented "show on all desktops" API).
- 64-bit Windows is assumed (the interop uses the `*WindowLongPtr` entry points).
