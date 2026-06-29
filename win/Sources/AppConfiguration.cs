namespace GlassFace;

/// <summary>
/// Centralized, tunable configuration. Plain data with no behavior, injected into the
/// collaborators that need it — so they depend on values, not on scattered globals.
///
/// Note: unlike the macOS build, this Windows port intentionally has no heart /
/// hand-gesture detection, so the gesture-related tunables are absent.
/// </summary>
public sealed class AppConfiguration
{
    // Opacity (0.0 = invisible, 1.0 = opaque).
    public float DefaultOpacity { get; init; } = 0.35f;
    public float OpacityStep { get; init; } = 0.10f;
}
