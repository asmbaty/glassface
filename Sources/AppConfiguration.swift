import Foundation

/// Centralized, tunable configuration. Plain data with no behavior, injected into the
/// collaborators that need it — so they depend on values, not on scattered globals.
struct AppConfiguration {
    // Opacity
    var defaultOpacity: Float = 0.35
    var opacityStep: Float = 0.10

    // Heart overlay
    var heartSize: CGFloat = 170

    // Heart-gesture thresholds (Vision-normalized distances, 0...1 across the frame).
    var maxIndexTipGap: CGFloat = 0.14
    var maxThumbTipGap: CGFloat = 0.22
    var minJointConfidence: Float = 0.3

    // Frame processing: run hand detection on every Nth frame to ease CPU.
    var frameProcessingStride = 2

    // Frames the heart may go undetected before it fades out (debounces flicker).
    var heartHideGraceFrames = 5
}
