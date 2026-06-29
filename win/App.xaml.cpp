#include "pch.h"
#include "App.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::GlassFace::implementation
{
    App::App()
    {
#if defined _DEBUG && !defined DISABLE_XAML_GENERATED_BREAK_ON_UNHANDLED_EXCEPTION
        UnhandledException([](IInspectable const&, UnhandledExceptionEventArgs const& e)
        {
            if (IsDebuggerPresent())
            {
                auto errorMessage = e.Message();
                __debugbreak();
            }
        });
#endif
    }

    // Entry point of the running app. We have no main window — GlassFace lives in the
    // system tray — so the coordinator builds the overlays and owns the whole lifetime.
    void App::OnLaunched(LaunchActivatedEventArgs const&)
    {
        m_coordinator = std::make_unique<glassface::AppCoordinator>();
        m_coordinator->Start();
    }
}
