import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings: BlurSettings = BlurSettings.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 14) {
            // Header Bar
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("AG-SpatialPrivacy")
                        .font(.system(size: 13, weight: .bold))
                    Text("AirPods Head-Tracking Privacy Screen")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.bottom, 2)

            Divider()

            // Status Card
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)

                    Text(connectionText)
                        .font(.system(size: 11, weight: .medium))
                }

                Spacer()

                Button(action: {
                    settings.calibrateCenter()
                }) {
                    Label("Calibrate Center", systemImage: "scope")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)

            // Live Angle Gauge
            AngleGaugeView(settings: settings)

            // Manual Simulation Slider (Always accessible or when in manualDemo mode)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Test Simulation Slider")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text(String(format: "%.1f°", settings.manualYawDegrees))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Slider(value: $settings.manualYawDegrees, in: -45...45, step: 0.5) {
                    Text("Test Slider")
                } onEditingChanged: { isEditing in
                    if isEditing && settings.trackingSource != .manualDemo {
                        settings.trackingSource = .manualDemo
                    }
                    settings.updateRawYaw(radians: settings.manualYawDegrees * .pi / 180.0)
                }
                .onChange(of: settings.manualYawDegrees) { _, newVal in
                    if settings.trackingSource == .manualDemo {
                        settings.updateRawYaw(radians: newVal * .pi / 180.0)
                    }
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(8)

            Divider()

            // Settings Controls
            VStack(alignment: .leading, spacing: 10) {
                // Tracking Source
                HStack {
                    Text("Tracking Source")
                        .font(.system(size: 11))
                    Spacer()
                    Picker("", selection: $settings.trackingSource) {
                        ForEach(TrackingSource.allCases) { source in
                            Label(source.rawValue, systemImage: source.icon)
                                .tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                    .onChange(of: settings.trackingSource) { _, newSource in
                        handleTrackingSourceChange(newSource)
                    }
                }

                // Blur Mode
                HStack {
                    Text("Privacy Mode")
                        .font(.system(size: 11))
                    Spacer()
                    Picker("", selection: $settings.blurDirectionMode) {
                        ForEach(BlurDirectionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }

                // Blur Style
                HStack {
                    Text("Blur Appearance")
                        .font(.system(size: 11))
                    Spacer()
                    Picker("", selection: $settings.blurStyle) {
                        ForEach(BlurStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }

                // Sensitivity Slider
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Sensitivity (Threshold)")
                            .font(.system(size: 11))
                        Spacer()
                        Text("\(Int(settings.sensitivityDegrees))°")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.sensitivityDegrees, in: 10...60, step: 1)
                }

                // Deadzone Slider
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Center Deadzone")
                            .font(.system(size: 11))
                        Spacer()
                        Text("\(Int(settings.deadzoneDegrees))°")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.deadzoneDegrees, in: 1...15, step: 1)
                }
            }

            Divider()

            // Footer
            HStack {
                Button(action: {
                    settings.manualYawDegrees = 0
                    settings.updateRawYaw(radians: 0)
                }) {
                    Text("Reset")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit Mac Blur")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var connectionColor: Color {
        switch settings.trackingSource {
        case .airpods:
            return settings.isAirPodsConnected ? .green : .orange
        case .camera:
            return settings.isCameraActive ? .green : .orange
        case .manualDemo:
            return .purple
        }
    }

    private var connectionText: String {
        switch settings.trackingSource {
        case .airpods:
            return settings.isAirPodsConnected ? "AirPods Connected" : "Waiting for AirPods..."
        case .camera:
            return settings.isCameraActive ? "Webcam Face Active" : "Starting Camera..."
        case .manualDemo:
            return "Manual Demo Active"
        }
    }

    private func handleTrackingSourceChange(_ newSource: TrackingSource) {
        if newSource == .camera {
            CameraFaceTracker.shared.start()
        } else {
            CameraFaceTracker.shared.stop()
        }
        if newSource == .airpods {
            AirPodsTracker.shared.start()
        }
    }
}
