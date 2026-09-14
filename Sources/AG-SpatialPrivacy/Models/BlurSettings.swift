import Foundation
import Combine
import SwiftUI

public enum TrackingSource: String, CaseIterable, Identifiable {
    case airpods = "AirPods Motion"
    case camera = "Webcam Face"
    case manualDemo = "Manual Simulation"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .airpods: return "airpodspro"
        case .camera: return "camera.fill"
        case .manualDemo: return "slider.horizontal.3"
        }
    }
}

public enum BlurDirectionMode: String, CaseIterable, Identifiable {
    case oppositeGaze = "Opposite Gaze (Default)"
    case followGaze = "Follow Gaze"
    case fullScreen = "Full Screen on Look-Away"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .oppositeGaze: return "Blurs the side of the screen you look away from"
        case .followGaze: return "Blurs the side of the screen you look towards"
        case .fullScreen: return "Blurs the entire screen whenever you look away"
        }
    }
}

public enum BlurStyle: String, CaseIterable, Identifiable {
    case frostedDark = "Frosted Dark"
    case frostedLight = "Frosted Light"
    case privacyBlackout = "Blackout Shield"

    public var id: String { rawValue }
}

public enum BlurSide {
    case none
    case left
    case right
    case full
}

@MainActor
public final class BlurSettings: ObservableObject {
    public static let shared = BlurSettings()

    // Preferences with UserDefaults persistence
    @AppStorage("isEnabled") public var isEnabled: Bool = true
    @AppStorage("trackingSourceRaw") private var trackingSourceRaw: String = TrackingSource.airpods.rawValue
    @AppStorage("blurDirectionModeRaw") private var blurDirectionModeRaw: String = BlurDirectionMode.oppositeGaze.rawValue
    @AppStorage("blurStyleRaw") private var blurStyleRaw: String = BlurStyle.frostedDark.rawValue
    @AppStorage("sensitivityDegrees") public var sensitivityDegrees: Double = 30.0
    @AppStorage("deadzoneDegrees") public var deadzoneDegrees: Double = 5.0
    @AppStorage("featherWidth") public var featherWidth: Double = 180.0
    @AppStorage("blurRadius") public var blurRadius: Double = 35.0

    // Enums
    public var trackingSource: TrackingSource {
        get { TrackingSource(rawValue: trackingSourceRaw) ?? .airpods }
        set {
            objectWillChange.send()
            trackingSourceRaw = newValue.rawValue
            resetAngles()
        }
    }

    public var blurDirectionMode: BlurDirectionMode {
        get { BlurDirectionMode(rawValue: blurDirectionModeRaw) ?? .oppositeGaze }
        set {
            objectWillChange.send()
            blurDirectionModeRaw = newValue.rawValue
            recalculateBlur(effectiveDeg: currentYawDegrees)
        }
    }

    public var blurStyle: BlurStyle {
        get { BlurStyle(rawValue: blurStyleRaw) ?? .frostedDark }
        set {
            objectWillChange.send()
            blurStyleRaw = newValue.rawValue
        }
    }

    // Live state
    @Published public var referenceYaw: Double = 0.0
    @Published public var rawYawDegrees: Double = 0.0
    @Published public var currentYawDegrees: Double = 0.0
    @Published public var currentBlurFraction: Double = 0.0
    @Published public var currentSide: BlurSide = .none
    @Published public var isAirPodsConnected: Bool = false
    @Published public var isCameraActive: Bool = false
    @Published public var manualYawDegrees: Double = 0.0

    private init() {}

    public func resetAngles() {
        manualYawDegrees = 0.0
        rawYawDegrees = 0.0
        currentYawDegrees = 0.0
        currentBlurFraction = 0.0
        currentSide = .none
        referenceYaw = 0.0
    }

    public func calibrateCenter() {
        referenceYaw = rawYawDegrees * .pi / 180.0
        if trackingSource == .manualDemo {
            resetAngles()
        }
    }

    public func updateManualYaw(degrees: Double) {
        manualYawDegrees = degrees
        currentYawDegrees = degrees
        recalculateBlur(effectiveDeg: degrees)
    }

    public func updateRawYaw(radians: Double) {
        let rawDeg = radians * 180.0 / .pi
        rawYawDegrees = rawDeg

        let calibratedDeg = (radians - referenceYaw) * 180.0 / .pi
        let effectiveDeg: Double

        if trackingSource == .manualDemo {
            effectiveDeg = manualYawDegrees
        } else {
            effectiveDeg = calibratedDeg
        }

        currentYawDegrees = effectiveDeg
        recalculateBlur(effectiveDeg: effectiveDeg)
    }

    public func recalculateBlur(effectiveDeg: Double) {
        let absDeg = abs(effectiveDeg)
        if !isEnabled || absDeg <= deadzoneDegrees {
            currentBlurFraction = 0.0
            currentSide = .none
        } else {
            let normalized = min(1.0, (absDeg - deadzoneDegrees) / max(1.0, sensitivityDegrees - deadzoneDegrees))
            currentBlurFraction = normalized

            if blurDirectionMode == .fullScreen {
                currentSide = .full
            } else if blurDirectionMode == .oppositeGaze {
                // When looking right (+deg), blur left side. When looking left (-deg), blur right side.
                currentSide = effectiveDeg > 0 ? .left : .right
            } else {
                // followGaze
                currentSide = effectiveDeg > 0 ? .right : .left
            }
        }
    }
}
