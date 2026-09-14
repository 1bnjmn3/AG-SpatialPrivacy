import SwiftUI

public struct AngleGaugeView: View {
    @ObservedObject var settings: BlurSettings

    public init(settings: BlurSettings) {
        self.settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Head Orientation", systemImage: "person.badge.shield.checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Text(angleDescription)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Gauge Bar Track
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let midX = w / 2.0
                let maxAngle: Double = 50.0

                // Clamp angle to -50...50 for display
                let clampedAngle = max(-maxAngle, min(maxAngle, settings.currentYawDegrees))
                let markerX = midX + (clampedAngle / maxAngle) * (w / 2.0)

                // Deadzone safe region width
                let deadzoneHalfWidth = (settings.deadzoneDegrees / maxAngle) * (w / 2.0)

                ZStack(alignment: .leading) {
                    // 1. Dark/Subtle track background
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.85))

                    // 2. Deadzone safe region in center
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.18))
                        .frame(width: max(8, deadzoneHalfWidth * 2), height: h - 4)
                        .position(x: midX, y: h / 2)

                    // 3. Dynamic blur fill
                    if settings.isEnabled && settings.currentBlurFraction > 0.01 {
                        if settings.currentSide == .left {
                            // Left side blur active
                            let blurW = w * CGFloat(settings.currentBlurFraction) * 0.5
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    colors: [.cyan.opacity(0.75), .blue.opacity(0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: blurW, height: h)
                                .position(x: blurW / 2, y: h / 2)
                        } else if settings.currentSide == .right {
                            // Right side blur active
                            let blurW = w * CGFloat(settings.currentBlurFraction) * 0.5
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.15), .cyan.opacity(0.75)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: blurW, height: h)
                                .position(x: w - blurW / 2, y: h / 2)
                        } else if settings.currentSide == .full {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.45))
                                .frame(width: w, height: h)
                        }
                    }

                    // 4. Center 0° tick line
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 1.5, height: h - 4)
                        .position(x: midX, y: h / 2)

                    // 5. Head Position Marker with spring animation
                    Circle()
                        .fill(markerColor)
                        .frame(width: 13, height: 13)
                        .shadow(color: markerColor.opacity(0.4), radius: 3, x: 0, y: 1)
                        .position(x: max(7, min(w - 7, markerX)), y: h / 2)
                        .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.75), value: markerX)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )
            }
            .frame(height: 20)

            // Scale Labels
            HStack {
                Text("← 50° L")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Center 0°")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("50° R →")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var angleDescription: String {
        guard settings.isEnabled else {
            return "Paused"
        }

        let deg = settings.currentYawDegrees
        if abs(deg) <= settings.deadzoneDegrees {
            return "Facing (0°)"
        }

        let dirStr = deg > 0 ? String(format: "+%.1f° R", deg) : String(format: "%.1f° L", deg)
        if settings.currentBlurFraction > 0.01 {
            return "\(dirStr) · \(Int(settings.currentBlurFraction * 100))% Blur"
        } else {
            return "\(dirStr) · Clear"
        }
    }

    private var statusColor: Color {
        if !settings.isEnabled {
            return .secondary
        } else if settings.currentBlurFraction > 0.01 {
            return .cyan
        } else {
            return .green
        }
    }

    private var markerColor: Color {
        if !settings.isEnabled {
            return .secondary
        } else if settings.currentBlurFraction > 0.01 {
            return .cyan
        } else {
            return .green
        }
    }
}
