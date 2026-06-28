import Vision

/// A detected two-hand heart, in Vision-normalized coordinates (bottom-left origin).
struct HeartGesture {
    let indexMidpoint: CGPoint
    let thumbMidpoint: CGPoint
}

/// Receives heart-gesture updates. Implemented by whatever drives the overlay.
protocol HeartGestureRecognizerDelegate: AnyObject {
    /// Always called on the main thread. `nil` means "no heart in this frame".
    func recognizer(_ recognizer: HeartGestureRecognizer, didUpdate gesture: HeartGesture?)
}

/// Turns camera frames into an optional `HeartGesture` using Vision hand-pose detection.
/// Single responsibility: pixels in, gesture out. Knows nothing about windows or layers.
final class HeartGestureRecognizer: FrameConsumer {
    weak var delegate: HeartGestureRecognizerDelegate?
    var isEnabled = true

    private let config: AppConfiguration
    private let request: VNDetectHumanHandPoseRequest
    private var frameIndex = 0

    init(config: AppConfiguration) {
        self.config = config
        request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
    }

    func consume(pixelBuffer: CVPixelBuffer) {
        guard isEnabled else { return }
        frameIndex &+= 1
        guard frameIndex % config.frameProcessingStride == 0 else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
        let gesture = heart(from: request.results ?? [])

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.recognizer(self, didUpdate: gesture)
        }
    }

    /// Two-hand heart: index fingertips meet near the top, thumb tips meet near the bottom.
    private func heart(from hands: [VNHumanHandPoseObservation]) -> HeartGesture? {
        guard hands.count >= 2 else { return nil }
        guard let i0 = tip(hands[0], .indexTip), let i1 = tip(hands[1], .indexTip),
              let t0 = tip(hands[0], .thumbTip), let t1 = tip(hands[1], .thumbTip) else { return nil }

        let indexMid = midpoint(i0, i1)
        let thumbMid = midpoint(t0, t1)
        guard distance(i0, i1) < config.maxIndexTipGap,
              distance(t0, t1) < config.maxThumbTipGap,
              indexMid.y > thumbMid.y else { return nil }   // index tips above thumb tips (y-up)

        return HeartGesture(indexMidpoint: indexMid, thumbMidpoint: thumbMid)
    }

    private func tip(_ observation: VNHumanHandPoseObservation,
                     _ joint: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        guard let point = try? observation.recognizedPoint(joint),
              point.confidence > config.minJointConfidence else { return nil }
        return point.location
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
