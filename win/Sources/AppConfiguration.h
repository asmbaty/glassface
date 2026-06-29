#pragma once

namespace glassface
{
    // Centralized, tunable configuration. Plain data with no behavior, injected into the
    // collaborators that need it — so they depend on values, not on scattered globals.
    //
    // Note: unlike the macOS build, this Windows port intentionally has no heart /
    // hand-gesture detection, so the gesture-related tunables are absent.
    struct AppConfiguration
    {
        // Opacity (0.0 = invisible, 1.0 = opaque).
        float defaultOpacity = 0.35f;
        float opacityStep = 0.10f;
    };
}
