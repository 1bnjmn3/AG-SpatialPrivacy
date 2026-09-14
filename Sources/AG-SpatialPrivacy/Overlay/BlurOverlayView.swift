import Cocoa
import QuartzCore

public final class BlurOverlayView: NSView {
    private let visualEffectView = NSVisualEffectView()
    private let tintView = NSView()
    private let maskLayer = CAGradientLayer()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true
        autoresizingMask = [.width, .height]

        // 1. Hardware backdrop blur view
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .fullScreenUI
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        addSubview(visualEffectView)

        // 2. Tint overlay view for rich frosted appearance
        tintView.frame = bounds
        tintView.autoresizingMask = [.width, .height]
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.45).cgColor
        addSubview(tintView)

        // 3. Feathered gradient mask on root layer
        maskLayer.frame = bounds
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer?.mask = maskLayer
    }

    public override func layout() {
        super.layout()
        visualEffectView.frame = bounds
        tintView.frame = bounds
        maskLayer.frame = bounds
    }

    public func update(fraction: Double, side: BlurSide, style: BlurStyle, featherWidth: Double) {
        let width = bounds.width
        guard width > 0 else { return }

        // Update tint color based on style
        switch style {
        case .frostedDark:
            visualEffectView.material = .fullScreenUI
            tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.50).cgColor
        case .frostedLight:
            visualEffectView.material = .underWindowBackground
            tintView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.40).cgColor
        case .privacyBlackout:
            visualEffectView.material = .fullScreenUI
            tintView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.92).cgColor
        }

        guard fraction > 0.001, side != .none else {
            // Screen is clear
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.18)
            alphaValue = 0.0
            CATransaction.commit()
            return
        }

        let featherFraction = min(0.35, featherWidth / width)
        let span = fraction * 0.95 // up to 95% across screen, or 100% on full

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.08) // 60-120fps fluid response

        alphaValue = 1.0

        switch side {
        case .left:
            // Blur comes in from left
            let edge = span
            let featherEnd = min(1.0, edge + featherFraction)

            maskLayer.colors = [
                NSColor.white.cgColor,
                NSColor.white.cgColor,
                NSColor.clear.cgColor,
                NSColor.clear.cgColor
            ]
            maskLayer.locations = [
                0.0,
                NSNumber(value: edge),
                NSNumber(value: featherEnd),
                1.0
            ]

        case .right:
            // Blur comes in from right
            let edge = 1.0 - span
            let featherStart = max(0.0, edge - featherFraction)

            maskLayer.colors = [
                NSColor.clear.cgColor,
                NSColor.clear.cgColor,
                NSColor.white.cgColor,
                NSColor.white.cgColor
            ]
            maskLayer.locations = [
                0.0,
                NSNumber(value: featherStart),
                NSNumber(value: edge),
                1.0
            ]

        case .full:
            maskLayer.colors = [
                NSColor.white.cgColor,
                NSColor.white.cgColor
            ]
            maskLayer.locations = [0.0, 1.0]

        case .none:
            alphaValue = 0.0
        }

        CATransaction.commit()
    }
}
