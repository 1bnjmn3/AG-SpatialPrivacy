import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings: BlurSettings = BlurSettings.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Header Bar
            HStack(spacing: 10) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("AG-SpatialPrivacy")
                        .font(.system(size: 14, weight: .bold))
                    Text("Spatial Gaze Privacy for macOS")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: settings.isEnabled) { _, _ in
                        settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                    }
            }
            .padding(.horizontal, 4)

            // 1. Device Status & Calibration Card
            HStack(spacing: 10) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(connectionColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: connectionColor.opacity(0.6), radius: 3)

                    Text(connectionText)
                        .font(.system(size: 11.5, weight: .medium))
                }

                Spacer()

                Button(action: {
                    settings.calibrateCenter()
                }) {
                    Label("Calibrate Center", systemImage: "scope")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
            )

            // 2. Live Head Orientation Gauge Card
            AngleGaugeView(settings: settings)
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
                )

            // 3. Test Simulation Slider Card (Only visible in Manual Simulation mode)
            if settings.trackingSource == .manualDemo {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Simulation Test Slider", systemImage: "slider.horizontal.3")
                            .font(.system(size: 11.5, weight: .semibold))

                        Spacer()

                        Text(String(format: "%+.1f°", settings.manualYawDegrees))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Color.cyan.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Slider(value: $settings.manualYawDegrees, in: -45...45, step: 0.5)
                        .labelsHidden()
                        .onChange(of: settings.manualYawDegrees) { _, newVal in
                            settings.updateManualYaw(degrees: newVal)
                        }

                    HStack {
                        Text("← Look Left (-45°)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Look Right (+45°) →")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }

            // 4. Configuration Preferences Card
            VStack(spacing: 10) {
                // Tracking Source Picker
                HStack {
                    Label("Tracking Source", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 11.5))
                    Spacer()
                    Picker("", selection: $settings.trackingSource) {
                        ForEach(TrackingSource.allCases) { source in
                            Label(source.rawValue, systemImage: source.icon)
                                .tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 180, maxWidth: 200)
                    .onChange(of: settings.trackingSource) { _, newSource in
                        handleTrackingSourceChange(newSource)
                    }
                }

                Divider()

                // Privacy Mode Picker
                HStack {
                    Label("Privacy Mode", systemImage: "lock.shield")
                        .font(.system(size: 11.5))
                    Spacer()
                    Picker("", selection: $settings.blurDirectionMode) {
                        ForEach(BlurDirectionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 180, maxWidth: 200)
                }

                Divider()

                // Blur Appearance Style Picker
                HStack {
                    Label("Blur Appearance", systemImage: "sparkles")
                        .font(.system(size: 11.5))
                    Spacer()
                    Picker("", selection: $settings.blurStyle) {
                        ForEach(BlurStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 180, maxWidth: 200)
                }

                Divider()

                // Sensitivity Threshold Slider
                VStack(spacing: 3) {
                    HStack {
                        Label("Sensitivity (Threshold)", systemImage: "speedometer")
                            .font(.system(size: 11.5))
                        Spacer()
                        if settings.sensitivityDegrees != 30.0 {
                            Button(action: {
                                settings.sensitivityDegrees = 30.0
                                settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)
                            .help("Reset sensitivity to default (30°)")
                        }
                        Text("\(Int(settings.sensitivityDegrees))°")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.sensitivityDegrees, in: 10...60, step: 1)
                        .labelsHidden()
                        .onChange(of: settings.sensitivityDegrees) { _, _ in
                            settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                        }
                }

                Divider()

                // Center Deadzone Slider
                VStack(spacing: 3) {
                    HStack {
                        Label("Center Deadzone", systemImage: "circle.circle")
                            .font(.system(size: 11.5))
                        Spacer()
                        if settings.deadzoneDegrees != 5.0 {
                            Button(action: {
                                settings.deadzoneDegrees = 5.0
                                settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)
                            .help("Reset deadzone to default (5°)")
                        }
                        Text("\(Int(settings.deadzoneDegrees))°")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $settings.deadzoneDegrees, in: 1...15, step: 1)
                        .labelsHidden()
                        .onChange(of: settings.deadzoneDegrees) { _, _ in
                            settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                        }
                }

                // Default Reset Button for Sliders
                HStack {
                    Spacer()
                    Button(action: {
                        settings.sensitivityDegrees = 30.0
                        settings.deadzoneDegrees = 5.0
                        settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                            Text("Reset to Defaults (30° / 5°)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(isCustomThresholds ? .cyan : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isCustomThresholds ? Color.cyan.opacity(0.35) : Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isCustomThresholds)
                }
                .padding(.top, 2)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 0.5)
            )

            // 5. Footer
            HStack {
                Button(action: {
                    settings.resetAngles()
                    settings.sensitivityDegrees = 30.0
                    settings.deadzoneDegrees = 5.0
                    settings.blurDirectionMode = .oppositeGaze
                    settings.blurStyle = .frostedDark
                }) {
                    Text("Reset Defaults")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit AG-SpatialPrivacy")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 380)
        .animation(.easeInOut(duration: 0.22), value: settings.trackingSource)
    }

    private var isCustomThresholds: Bool {
        settings.sensitivityDegrees != 30.0 || settings.deadzoneDegrees != 5.0
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
        settings.resetAngles()

        if newSource == .camera {
            AirPodsTracker.shared.stop()
            CameraFaceTracker.shared.start()
        } else if newSource == .airpods {
            CameraFaceTracker.shared.stop()
            AirPodsTracker.shared.start()
        } else {
            // Manual Demo
            AirPodsTracker.shared.stop()
            CameraFaceTracker.shared.stop()
        }
    }
}
