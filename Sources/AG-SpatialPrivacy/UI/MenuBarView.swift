import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var settings: BlurSettings = BlurSettings.shared
    @ObservedObject var launchManager: LaunchAtLoginManager = LaunchAtLoginManager.shared

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                // Header Bar
                HStack(spacing: 8) {
                    if let appIcon = NSApp.applicationIconImage {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(radius: 1)
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("AG-SpatialPrivacy")
                            .font(.system(size: 13, weight: .bold))
                        Text("Spatial Gaze Privacy for macOS")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $settings.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                        .onChange(of: settings.isEnabled) { _, _ in
                            settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                        }
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)

                // 1. Device Status & Calibration Card
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(connectionColor)
                            .frame(width: 7, height: 7)
                            .shadow(color: connectionColor.opacity(0.5), radius: 2)

                        Text(connectionText)
                            .font(.system(size: 11, weight: .medium))
                    }

                    Spacer()

                    Button(action: {
                        settings.calibrateCenter()
                    }) {
                        Label("Calibrate Center", systemImage: "scope")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor).opacity(0.25), lineWidth: 0.5)
                )

                // 2. Live Head Orientation Gauge Card
                AngleGaugeView(settings: settings)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor).opacity(0.25), lineWidth: 0.5)
                    )

                // 3. Test Simulation Slider Card (Only visible in Manual Simulation mode)
                if settings.trackingSource == .manualDemo {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label("Simulation Test Slider", systemImage: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .semibold))

                            Spacer()

                            Text(String(format: "%+.1f°", settings.manualYawDegrees))
                                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.cyan.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        Slider(value: $settings.manualYawDegrees, in: -45...45, step: 0.5)
                            .labelsHidden()
                            .controlSize(.small)
                            .onChange(of: settings.manualYawDegrees) { _, newVal in
                                settings.updateManualYaw(degrees: newVal)
                            }

                        HStack {
                            Text("← Look Left (-45°)")
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Look Right (+45°) →")
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor).opacity(0.25), lineWidth: 0.5)
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }

                // 4. Configuration Preferences Card
                VStack(spacing: 7) {
                    // Tracking Source Picker
                    HStack {
                        Label("Tracking Source", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11))
                        Spacer()
                        Picker("", selection: $settings.trackingSource) {
                            ForEach(TrackingSource.allCases) { source in
                                Label(source.rawValue, systemImage: source.icon)
                                    .tag(source)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                        .onChange(of: settings.trackingSource) { _, newSource in
                            handleTrackingSourceChange(newSource)
                        }
                    }

                    Divider()
                        .padding(.vertical, -1)

                    // Privacy Mode Picker
                    HStack {
                        Label("Privacy Mode", systemImage: "lock.shield")
                            .font(.system(size: 11))
                        Spacer()
                        Picker("", selection: $settings.blurDirectionMode) {
                            ForEach(BlurDirectionMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                    }

                    Divider()
                        .padding(.vertical, -1)

                    // Blur Appearance Style Picker
                    HStack {
                        Label("Blur Appearance", systemImage: "sparkles")
                            .font(.system(size: 11))
                        Spacer()
                        Picker("", selection: $settings.blurStyle) {
                            ForEach(BlurStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                    }

                    Divider()
                        .padding(.vertical, -1)

                    // Sensitivity Threshold Slider
                    VStack(spacing: 2) {
                        HStack {
                            Label("Sensitivity", systemImage: "speedometer")
                                .font(.system(size: 11))
                            Spacer()
                            if settings.sensitivityDegrees != 30.0 {
                                Button(action: {
                                    settings.sensitivityDegrees = 30.0
                                    settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                                .buttonStyle(.plain)
                                .help("Reset sensitivity to default (30°)")
                            }
                            Text("\(Int(settings.sensitivityDegrees))°")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.sensitivityDegrees, in: 10...60, step: 1)
                            .labelsHidden()
                            .controlSize(.small)
                            .onChange(of: settings.sensitivityDegrees) { _, _ in
                                settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                            }
                    }

                    Divider()
                        .padding(.vertical, -1)

                    // Center Deadzone Slider
                    VStack(spacing: 2) {
                        HStack {
                            Label("Center Deadzone", systemImage: "circle.circle")
                                .font(.system(size: 11))
                            Spacer()
                            if settings.deadzoneDegrees != 5.0 {
                                Button(action: {
                                    settings.deadzoneDegrees = 5.0
                                    settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                                .buttonStyle(.plain)
                                .help("Reset deadzone to default (5°)")
                            }
                            Text("\(Int(settings.deadzoneDegrees))°")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.deadzoneDegrees, in: 1...15, step: 1)
                            .labelsHidden()
                            .controlSize(.small)
                            .onChange(of: settings.deadzoneDegrees) { _, _ in
                                settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                            }
                    }

                    Divider()
                        .padding(.vertical, -1)

                    // Start on Startup Toggle
                    HStack {
                        Label("Start on Startup", systemImage: "arrow.clockwise.circle")
                            .font(.system(size: 11))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { launchManager.isEnabled },
                            set: { launchManager.setEnabled($0) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                    }

                    // Default Reset Button for Sliders
                    HStack {
                        Spacer()
                        Button(action: {
                            settings.sensitivityDegrees = 30.0
                            settings.deadzoneDegrees = 5.0
                            settings.recalculateBlur(effectiveDeg: settings.currentYawDegrees)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 8.5, weight: .bold))
                                Text("Reset to Defaults (30° / 5°)")
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundColor(isCustomThresholds ? .cyan : .secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color(NSColor.windowBackgroundColor).opacity(0.7))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isCustomThresholds ? Color.cyan.opacity(0.35) : Color.secondary.opacity(0.18), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isCustomThresholds)
                    }
                    .padding(.top, 1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor).opacity(0.25), lineWidth: 0.5)
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
                            .font(.system(size: 10.5))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Quit AG-SpatialPrivacy")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.top, 1)
            }
            .padding(10)
        }
        .frame(width: 360)
        .frame(maxHeight: 460)
        .animation(.easeInOut(duration: 0.2), value: settings.trackingSource)
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
