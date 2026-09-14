import Cocoa
import QuartzCore

public final class BlurOverlayView: NSView {
    private let visualEffectView = NSVisualEffectView()
    private let tintView = NSView()
    private let vignetteView = NSView()
    private let maskLayer = CAGradientLayer()
    private let specularLineLayer = CAGradientLayer()

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
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        addSubview(visualEffectView)

        // 2. Tint overlay view for rich, deep frosted appearance
        tintView.frame = bounds
        tintView.autoresizingMask = [.width, .height]
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor(deviceRed: 0.04, green: 0.05, blue: 0.07, alpha: 0.58).cgColor
        addSubview(tintView)

        // 3. Subtle edge vignette overlay
        vignetteView.frame = bounds
        vignetteView.autoresizingMask = [.width, .height]
        vignetteView.wantsLayer = true
        addSubview(vignetteView)

        // 4. Specular glass edge accent line
        specularLineLayer.colors = [
            NSColor.white.withAlphaComponent(0.0).cgColor,
            NSColor.white.withAlphaComponent(0.40).cgColor,
            NSColor.white.withAlphaComponent(0.45).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ]
        specularLineLayer.locations = [0.0, 0.2, 0.8, 1.0]
        specularLineLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        specularLineLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        specularLineLayer.opacity = 0.0
        layer?.addSublayer(specularLineLayer)

        // 5. Feathered gradient mask on root layer with smooth optical falloff
        maskLayer.frame = bounds
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer?.mask = maskLayer
    }

    public override func layout() {
        super.layout()
        visualEffectView.frame = bounds
        tintView.frame = bounds
        vignetteView.frame = bounds
        maskLayer.frame = bounds
    }

    public func update(fraction: Double, side: BlurSide, style: BlurStyle, featherWidth: Double) {
        let width = bounds.width
        let height = bounds.height
        guard width > 0, height > 0 else { return }

        // Update tint color based on style
        switch style {
        case .frostedDark:
            visualEffectView.material = .hudWindow
            tintView.layer?.backgroundColor = NSColor(deviceRed: 0.04, green: 0.05, blue: 0.07, alpha: 0.60).cgColor
            specularLineLayer.colors = [
                NSColor.cyan.withAlphaComponent(0.0).cgColor,
                NSColor.white.withAlphaComponent(0.35).cgColor,
                NSColor.cyan.withAlphaComponent(0.45).cgColor,
                NSColor.cyan.withAlphaComponent(0.0).cgColor
            ]
        case .frostedLight:
            visualEffectView.material = .underWindowBackground
            tintView.layer?.backgroundColor = NSColor(deviceWhite: 1.0, alpha: 0.45).cgColor
            specularLineLayer.colors = [
                NSColor.white.withAlphaComponent(0.0).cgColor,
                NSColor.white.withAlphaComponent(0.70).cgColor,
                NSColor.white.withAlphaComponent(0.70).cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor
            ]
        case .privacyBlackout:
            visualEffectView.material = .hudWindow
            tintView.layer?.backgroundColor = NSColor(deviceWhite: 0.02, alpha: 0.94).cgColor
            specularLineLayer.colors = [
                NSColor.red.withAlphaComponent(0.0).cgColor,
                NSColor.red.withAlphaComponent(0.40).cgColor,
                NSColor.red.withAlphaComponent(0.40).cgColor,
                NSColor.red.withAlphaComponent(0.0).cgColor
            ]
        }

        guard fraction > 0.001, side != .none else {
            // Screen is clear
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.16)
            alphaValue = 0.0
            specularLineLayer.opacity = 0.0
            CATransaction.commit()
            return
        }

        let featherFraction = min(0.40, max(0.08, featherWidth / width))
        let span = fraction * 0.95

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.06) // Fluid 60-120fps response

        alphaValue = 1.0

        switch side {
        case .left:
            // Blur comes in from the left
            let edge = span
            let featherEnd = min(1.0, edge + featherFraction)

            // Multi-stop smoothstep Hermite falloff
            var colors: [CGColor] = [NSColor.white.cgColor]
            var locations: [NSNumber] = [0.0]

            if edge > 0.01 {
                colors.append(NSColor.white.cgColor)
                locations.append(NSNumber(value: edge))
            }

            let steps = 6
            let spanRange = featherEnd - edge
            if spanRange > 0.001 {
                for i in 1..<steps {
                    let t = Double(i) / Double(steps)
                    let smoothAlpha = 1.0 - (t * t * (3.0 - 2.0 * t))
                    let loc = edge + (t * spanRange)
                    colors.append(NSColor(deviceWhite: 1.0, alpha: CGFloat(smoothAlpha)).cgColor)
                    locations.append(NSNumber(value: loc))
                }
            }

            colors.append(NSColor.clear.cgColor)
            locations.append(NSNumber(value: featherEnd))

            if featherEnd < 0.999 {
                colors.append(NSColor.clear.cgColor)
                locations.append(1.0)
            }

            maskLayer.colors = colors
            maskLayer.locations = locations

            // Position specular highlight line along the blur edge
            let lineX = (edge + spanRange * 0.3) * width
            specularLineLayer.frame = CGRect(x: lineX - 1.0, y: 0, width: 2.0, height: height)
            specularLineLayer.opacity = Float(min(1.0, fraction * 1.5))

        case .right:
            // Blur comes in from the right
            let edge = 1.0 - span
            let featherStart = max(0.0, edge - featherFraction)

            var colors: [CGColor] = []
            var locations: [NSNumber] = []

            if featherStart > 0.001 {
                colors.append(NSColor.clear.cgColor)
                locations.append(0.0)
            }

            colors.append(NSColor.clear.cgColor)
            locations.append(NSNumber(value: featherStart))

            let steps = 6
            let spanRange = edge - featherStart
            if spanRange > 0.001 {
                for i in 1..<steps {
                    let t = Double(i) / Double(steps)
                    let smoothAlpha = t * t * (3.0 - 2.0 * t)
                    let loc = featherStart + (t * spanRange)
                    colors.append(NSColor(deviceWhite: 1.0, alpha: CGFloat(smoothAlpha)).cgColor)
                    locations.append(NSNumber(value: loc))
                }
            }

            colors.append(NSColor.white.cgColor)
            locations.append(NSNumber(value: edge))

            if edge < 0.999 {
                colors.append(NSColor.white.cgColor)
                locations.append(1.0)
            }

            maskLayer.colors = colors
            maskLayer.locations = locations

            // Position specular highlight line along the blur edge
            let lineX = (edge - spanRange * 0.3) * width
            specularLineLayer.frame = CGRect(x: lineX - 1.0, y: 0, width: 2.0, height: height)
            specularLineLayer.opacity = Float(min(1.0, fraction * 1.5))

        case .full:
            maskLayer.colors = [
                NSColor.white.cgColor,
                NSColor.white.cgColor
            ]
            maskLayer.locations = [0.0, 1.0]
            specularLineLayer.opacity = 0.0

        case .none:
            alphaValue = 0.0
            specularLineLayer.opacity = 0.0
        }

        CATransaction.commit()
    }
}
