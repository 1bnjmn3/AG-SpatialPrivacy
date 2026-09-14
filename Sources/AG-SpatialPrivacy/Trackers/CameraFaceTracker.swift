import Foundation
import AVFoundation
import Vision
import CoreMedia

public final class CameraFaceTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    public static let shared = CameraFaceTracker()

    private let captureSession = AVCaptureSession()
    private let sequenceHandler = VNSequenceRequestHandler()
    private let videoOutputQueue = DispatchQueue(label: "com.1bnjmn3.AG-SpatialPrivacy.VideoQueue", qos: .userInitiated)
    private var isRunning: Bool = false
    private var lastFrameTime: CFAbsoluteTime = 0
    private var filteredYaw: Double = 0.0
    private let smoothingFactor: Double = 0.35

    private override init() {
        super.init()
    }

    public func start() {
        guard !isRunning else { return }

        // Check camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.setupAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupAndStartSession()
                }
            }
        default:
            print("[CameraFaceTracker] Camera access denied or restricted")
        }
    }

    private func setupAndStartSession() {
        videoOutputQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .low // Lightweight preset for face tracking

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                               AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("[CameraFaceTracker] No camera device found")
                self.captureSession.commitConfiguration()
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

            if self.captureSession.canAddOutput(output) {
                self.captureSession.addOutput(output)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            self.isRunning = true

            Task { @MainActor in
                BlurSettings.shared.isCameraActive = true
            }
            print("[CameraFaceTracker] Camera tracking started")
        }
    }

    public func stop() {
        guard isRunning else { return }
        videoOutputQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.stopRunning()
            self.isRunning = false
            Task { @MainActor in
                BlurSettings.shared.isCameraActive = false
            }
            print("[CameraFaceTracker] Camera tracking stopped")
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CFAbsoluteTimeGetCurrent()
        // Throttle to max 20 fps for efficiency
        guard now - lastFrameTime >= 0.05 else { return }
        lastFrameTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self, error == nil,
                  let results = request.results as? [VNFaceObservation],
                  let firstFace = results.first else { return }

            // Extract yaw (head turn left/right). On macOS/Vision, yaw is NSNumber in radians
            if let yawNumber = firstFace.yaw {
                // Mirror for front camera
                let rawYaw = -yawNumber.doubleValue
                self.filteredYaw = (self.smoothingFactor * rawYaw) + ((1.0 - self.smoothingFactor) * self.filteredYaw)

                Task { @MainActor in
                    if BlurSettings.shared.trackingSource == .camera {
                        BlurSettings.shared.updateRawYaw(radians: self.filteredYaw)
                    }
                }
            }
        }

        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: .leftMirrored)
    }
}
