import Cocoa
import Combine

@MainActor
public final class BlurOverlayController: ObservableObject {
    public static let shared = BlurOverlayController()

    private var overlayWindows: [BlurOverlayWindow] = []
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupWindows()
        setupObservers()
    }

    public func setupWindows() {
        // Tear down old windows
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()

        // Create an overlay window for each screen
        for screen in NSScreen.screens {
            let window = BlurOverlayWindow(screen: screen)
            window.orderFront(nil)
            overlayWindows.append(window)
        }
    }

    private func setupObservers() {
        // Handle screen resolution / display connection changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.setupWindows()
                }
            }
            .store(in: &cancellables)

        // Observe blur state updates
        let settings = BlurSettings.shared
        Publishers.CombineLatest(
            settings.$currentBlurFraction,
            settings.$currentSide
        )
        .sink { [weak self] fraction, side in
            self?.updateWindows(fraction: fraction, side: side, style: settings.blurStyle, featherWidth: settings.featherWidth)
        }
        .store(in: &cancellables)

        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateWindows(
                        fraction: settings.currentBlurFraction,
                        side: settings.currentSide,
                        style: settings.blurStyle,
                        featherWidth: settings.featherWidth
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func updateWindows(fraction: Double, side: BlurSide, style: BlurStyle, featherWidth: Double) {
        for window in overlayWindows {
            window.update(fraction: fraction, side: side, style: style, featherWidth: featherWidth)
        }
    }
}
