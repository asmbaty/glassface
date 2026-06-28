import AVFoundation

/// Receives raw camera frames. Implemented by whatever wants to analyze them
/// (the gesture recognizer) — `CameraService` depends on this abstraction, not the concrete type.
protocol FrameConsumer: AnyObject {
    /// Called on the capture queue (off the main thread).
    func consume(pixelBuffer: CVPixelBuffer)
}

enum CameraError: Error {
    case noUsableDevice
}

/// Owns the `AVCaptureSession`: device discovery, wiring the video output, and
/// starting/stopping capture. Its single responsibility is supplying camera frames.
final class CameraService: NSObject {
    let session = AVCaptureSession()
    weak var frameConsumer: FrameConsumer?

    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.glassface.video")

    /// Builds the capture graph. Throws if no camera is available.
    func configure() throws {
        guard let device = Self.frontCamera(),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            throw CameraError.noUsableDevice
        }

        session.beginConfiguration()
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()
    }

    func start() { setRunning(true) }

    /// Starts/stops the session off the main thread (both calls block).
    func setRunning(_ running: Bool) {
        let session = self.session
        DispatchQueue.global(qos: .userInitiated).async {
            if running, !session.isRunning {
                session.startRunning()
            } else if !running, session.isRunning {
                session.stopRunning()
            }
        }
    }

    private static func frontCamera() -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
        return discovery.devices.first
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
            ?? AVCaptureDevice.default(for: .video)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frameConsumer?.consume(pixelBuffer: pixelBuffer)
    }
}
