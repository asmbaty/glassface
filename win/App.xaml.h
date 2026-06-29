#pragma once

#include "App.xaml.g.h"
#include "Sources/AppCoordinator.h"

namespace winrt::GlassFace::implementation
{
    // The XAML application object. It exists only to stand the app up and hand control to
    // the composition root (glassface::AppCoordinator); all behavior lives in Sources/.
    struct App : AppT<App>
    {
        App();
        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const& e);

    private:
        std::unique_ptr<glassface::AppCoordinator> m_coordinator;
    };
}
