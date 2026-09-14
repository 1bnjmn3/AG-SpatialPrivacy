import SwiftUI

public struct AngleGaugeView: View {
    @ObservedObject var settings: BlurSettings

    public init(settings: BlurSettings) {
        self.settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("HEAD ANGLE GAUGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                Spacer()

                Text(angleDescription)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor)
            }

            // Gauge Bar
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let midX = w / 2.0
                let maxAngle: Double = 50.0

                // Clamp angle to -50...50 for display
                let clampedAngle = max(-maxAngle, min(maxAngle, settings.currentYawDegrees))
                let markerX = midX + (clampedAngle / maxAngle) * (w / 2.0)

                // Deadzone regions
                let deadzoneWidth = (settings.deadzoneDegrees / maxAngle) * (w / 2.0)

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))

                    // Deadzone safe center zone
                    Rectangle()
                        .fill(Color.green.opacity(0.20))
                        .frame(width: deadzoneWidth * 2, height: h)
                        .position(x: midX, y: h / 2)

                    // Blur active fill
                    if settings.currentBlurFraction > 0.01 {
                        if settings.currentSide == .left {
                            // Left side blur active
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.blue.opacity(0.6), .blue.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: w * CGFloat(settings.currentBlurFraction) * 0.5, height: h)
                                .position(x: (w * CGFloat(settings.currentBlurFraction) * 0.5) / 2, y: h / 2)
                        } else if settings.currentSide == .right {
                            // Right side blur active
                            let blurW = w * CGFloat(settings.currentBlurFraction) * 0.5
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.blue.opacity(0.1), .blue.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: blurW, height: h)
                                .position(x: w - blurW / 2, y: h / 2)
                        } else if settings.currentSide == .full {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.4))
                                .frame(width: w, height: h)
                        }
                    }

                    // Center 0° line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 1.5, height: h)
                        .position(x: midX, y: h / 2)

                    // Moving Head marker
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                        .shadow(radius: 2)
                        .position(x: max(6, min(w - 6, markerX)), y: h / 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .frame(height: 18)

            // Labels under gauge
            HStack {
                Text("← Left 50°")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Center (0°)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Right 50° →")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var angleDescription: String {
        let deg = settings.currentYawDegrees
        let sideStr: String
        if abs(deg) <= settings.deadzoneDegrees {
            sideStr = "Facing Screen"
        } else if deg > 0 {
            sideStr = String(format: "+%.1f° Right", deg)
        } else {
            sideStr = String(format: "%.1f° Left", deg)
        }

        if settings.currentBlurFraction > 0.01 {
            return "\(sideStr) (Blur: \(Int(settings.currentBlurFraction * 100))%)"
        } else {
            return "\(sideStr) (Clear)"
        }
    }

    private var statusColor: Color {
        if !settings.isEnabled {
            return .secondary
        } else if settings.currentBlurFraction > 0.01 {
            return .blue
        } else {
            return .green
        }
    }
}
