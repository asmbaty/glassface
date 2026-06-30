#pragma once

#include <winrt/Windows.Foundation.h>
#include <winrt/Microsoft.UI.Dispatching.h>

#include "AppConfiguration.h"
#include "CameraService.h"
#include "OverlayCoordinator.h"
#include "HotKeyCenter.h"
#include "StatusMenu.h"

namespace glassface
{
    // Composition root. Builds the collaborators, wires them together, and orchestrates the
    // cross-cutting flows (camera setup, opacity, hot keys). It holds no rendering or capture
    // logic itself — each of those lives in its own single-responsibility type.
    class AppCoordinator
    {
    public:
        AppCoordinator();

        // Called once from App::OnLaunched, on the UI thread.
        void Start();

    private:
        winrt::fire_and_forget ConfigureCameraAsync();

        void SetOpacity(float value);   // single funnel for every opacity change
        void IncreaseOpacity();
        void DecreaseOpacity();
        void ConfigureHotKeys();
        void Quit();

        AppConfiguration m_config{};
        CameraService m_camera{};
        OverlayCoordinator m_overlay;
        HotKeyCenter m_hotKeys{};
        StatusMenu m_menu{};
        winrt::Microsoft::UI::Dispatching::DispatcherQueue m_dispatcher{ nullptr };
    };
}
