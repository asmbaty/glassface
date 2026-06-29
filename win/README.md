# GlassFace for Windows (WinUI 3 / C++)

A tiny native Windows app that shows your **front camera feed as a semi-transparent,
full-screen overlay** — while you keep using your PC completely normally. The overlay
floats above everything and **passes all clicks and keystrokes through** to the apps
underneath.

This is a Windows port of the macOS [GlassFace](../README.md), written in **C++/WinRT on
WinUI 3 (Windows App SDK)**. The macOS sources are untouched; everything here lives under
`win/`.

> **Note:** Unlike the macOS build, this Windows version has **no heart / hand-gesture
> detection** (by request). The overlay, tray, hot keys, camera, and multi-monitor support
> are all present.

## Requirements
- Windows 10 (build 17763 / 1809) or later — Windows 11 recommended
- **Visual Studio 2022** (17.8+) with these workloads/components:
  - *Desktop development with C++*
  - *Windows App SDK C++ Templates* (a.k.a. the WinUI/C++ component)
  - A recent Windows 10/11 SDK
- The referenced NuGet packages restore automatically on first build:
  `Microsoft.WindowsAppSDK`, `Microsoft.Windows.CppWinRT`, `Microsoft.Windows.SDK.BuildTools`.

## Build & run
1. Open **`GlassFace.sln`** in Visual Studio 2022.
2. Pick the **x64** (or **ARM64**) platform and the **Debug** or **Release** configuration.
3. Press **F5**. Visual Studio builds the MSIX, deploys it locally, and launches it.

On first launch Windows asks for **camera permission** — approve it (Settings → Privacy &
security → Camera). The transparent feed then covers your whole screen.

Command-line build (Developer Command Prompt):
```bat
msbuild GlassFace.sln /p:Configuration=Release /p:Platform=x64 /restore
```

## Tray icon & hotkeys
GlassFace lives in the **system tray** (ghost icon). Right- or left-click it for a menu
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
Almost everything tunable lives in **`Sources/AppConfiguration.h`**: `defaultOpacity`
(`0.0` = invisible, `1.0` = opaque; default `0.35`) and `opacityStep` (hotkey increment).
The camera defaults to the **front-facing** camera and the feed is **mirrored** (selfie
view) — see `CameraService::ConfigureAsync()` and the `ScaleTransform` in `ScreenOverlay`.
An overlay is created for **every connected display** automatically.

## How it works
The code mirrors the macOS app's small single-responsibility types, wired together by
`AppCoordinator` (the composition root); the XAML `App` is just the entry point.

| Concern | Type(s) |
|---------|---------|
| Configuration (all tunables) | `AppConfiguration` |
| Camera capture & frame delivery | `CameraService` |
| On-screen overlay | `OverlayCoordinator`, `ScreenOverlay`, `OverlayWindow` |
| Global hot keys (Win32) | `HotKeyCenter` |
| System tray | `StatusMenu`, `GhostIcon` |
| Errors | `AlertPresenter` |
| Win32 interop (monitors, click-through) | `NativeHelpers` |
| Wiring / orchestration | `App`, `AppCoordinator` |

Under the hood: one **WinUI 3 `Window` per display**, made borderless and always-on-top via
`OverlappedPresenter`, positioned with physical-pixel `AppWindow.MoveAndResize`, and made
**click-through** by adding `WS_EX_TRANSPARENT | WS_EX_LAYERED` to its HWND over a
transparent XAML background. The camera uses in-box WinRT **Media Capture**
(`MediaCapture` → `MediaFrameReader`, BGRA8) feeding a shared `SoftwareBitmapSource` drawn
into an `Image` at reduced opacity and mirrored. Global shortcuts use Win32 `RegisterHotKey`
on a message-only window; the tray uses `Shell_NotifyIcon` with a Win32 popup menu (WinUI 3
has no built-in tray).

### Why these choices?
WinUI 3 has no `CaptureElement` (it existed in UWP/WPF) and no tray API, so the camera
preview is rendered from frames via `SoftwareBitmapSource`, and the tray is built directly
on Win32. Transparency + click-through is achieved at the HWND level because WinUI 3 doesn't
expose a managed "click-through transparent window" switch.

## Notes
- The overlay sits above normal windows. It does not appear over another app's exclusive
  full-screen mode; use it on the normal desktop.
- The packaged build uses **placeholder tile/logo art** under `Assets/` — replace with real
  artwork as desired. (The in-app tray icon is drawn in code by `GhostIcon`.)
- Built and authored against Windows App SDK 1.5; newer 1.x releases should also work.
