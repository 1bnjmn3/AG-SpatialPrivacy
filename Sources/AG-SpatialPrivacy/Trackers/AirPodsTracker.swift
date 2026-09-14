import Foundation
import CoreMotion
import Combine

public final class AirPodsTracker: NSObject, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {
    public static let shared = AirPodsTracker()

    private let motionManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    private var filteredYaw: Double = 0.0
    private var isRunning: Bool = false
    private let smoothingFactor: Double = 0.22 // Low-pass EMA filter factor

    private override init() {
        super.init()
        queue.name = "com.1bnjmn3.AG-SpatialPrivacy.MotionQueue"
        queue.qualityOfService = .userInteractive
        motionManager.delegate = self
    }

    public func start() {
        guard motionManager.isDeviceMotionAvailable else {
            print("[AirPodsTracker] Device motion not available on this hardware")
            Task { @MainActor in
                BlurSettings.shared.isAirPodsConnected = false
            }
            return
        }

        guard !isRunning else { return }
        isRunning = true

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            let rawYaw = motion.attitude.yaw

            // Exponential Moving Average filter
            self.filteredYaw = (self.smoothingFactor * rawYaw) + ((1.0 - self.smoothingFactor) * self.filteredYaw)

            Task { @MainActor in
                if !BlurSettings.shared.isAirPodsConnected {
                    BlurSettings.shared.isAirPodsConnected = true
                }
                if BlurSettings.shared.trackingSource == .airpods {
                    BlurSettings.shared.updateRawYaw(radians: self.filteredYaw)
                }
            }
        }

        print("[AirPodsTracker] Started motion updates")
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        print("[AirPodsTracker] Stopped motion updates")
    }

    // MARK: - CMHeadphoneMotionManagerDelegate

    public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("[AirPodsTracker] AirPods connected!")
        Task { @MainActor in
            BlurSettings.shared.isAirPodsConnected = true
        }
    }

    public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("[AirPodsTracker] AirPods disconnected!")
        Task { @MainActor in
            BlurSettings.shared.isAirPodsConnected = false
        }
    }
}
