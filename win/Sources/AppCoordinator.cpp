#include "pch.h"
#include "AppCoordinator.h"
#include "AlertPresenter.h"

using namespace winrt;
using namespace winrt::Windows::Graphics::Imaging;
using namespace winrt::Microsoft::UI::Dispatching;
using namespace winrt::Microsoft::UI::Xaml;

namespace glassface
{
    AppCoordinator::AppCoordinator()
        : m_overlay(m_config)
    {
        m_camera.frameConsumer = [this](SoftwareBitmap bitmap) { m_overlay.Consume(bitmap); };
        m_menu.onIncrease = [this] { IncreaseOpacity(); };
        m_menu.onDecrease = [this] { DecreaseOpacity(); };
        m_menu.onQuit = [this] { Quit(); };
    }

    void AppCoordinator::Start()
    {
        m_dispatcher = DispatcherQueue::GetForCurrentThread();

        m_menu.Install();
        m_menu.UpdateOpacity(m_overlay.Opacity());
        m_overlay.BuildOverlays();
        ConfigureHotKeys();

        ConfigureCameraAsync();   // fire-and-forget; failures surface as alerts
    }

    fire_and_forget AppCoordinator::ConfigureCameraAsync()
    {
        auto dispatcher = m_dispatcher;
        try
        {
            co_await m_camera.ConfigureAsync();
        }
        catch (hresult_error const& e)
        {
            HRESULT code = static_cast<HRESULT>(e.code());
            dispatcher.TryEnqueue([code]
            {
                if (code == E_ACCESSDENIED) AlertPresenter::CameraPermissionDenied();
                else                        AlertPresenter::NoCamera();
            });
            co_return;
        }
        catch (...)
        {
            dispatcher.TryEnqueue([] { AlertPresenter::NoCamera(); });
            co_return;
        }

        co_await m_camera.StartAsync();
    }

    void AppCoordinator::SetOpacity(float value)
    {
        float applied = m_overlay.SetOpacity(value);
        m_menu.UpdateOpacity(applied);
        m_camera.SetRunningAsync(applied > 0.0f);   // camera genuinely off at 0% (privacy light out)
    }

    void AppCoordinator::IncreaseOpacity() { SetOpacity(m_overlay.Opacity() + m_config.opacityStep); }
    void AppCoordinator::DecreaseOpacity() { SetOpacity(m_overlay.Opacity() - m_config.opacityStep); }

    void AppCoordinator::ConfigureHotKeys()
    {
        m_hotKeys.Install();
        m_hotKeys.Bind('Q', [this] { Quit(); });
        m_hotKeys.Bind(VK_OEM_PLUS, [this] { IncreaseOpacity(); });   // '=' / '+'
        m_hotKeys.Bind(VK_OEM_MINUS, [this] { DecreaseOpacity(); });  // '-' / '_'

        // Number keys jump straight to a level: 1…9 → 10%…90%, 0 → 100%.
        for (UINT digit = 1; digit <= 9; ++digit)
        {
            float level = digit / 10.0f;
            m_hotKeys.Bind('0' + digit, [this, level] { SetOpacity(level); });
        }
        m_hotKeys.Bind('0', [this] { SetOpacity(1.0f); });
    }

    void AppCoordinator::Quit()
    {
        if (auto app = Application::Current())
            app.Exit();
    }
}
