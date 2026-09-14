import Cocoa

public final class BlurOverlayWindow: NSWindow {
    private let blurView: BlurOverlayView

    // Private SkyLight API signatures
    private typealias CGSMainConnectionIDFunc = @convention(c) () -> Int32
    private typealias SLSSetWindowBackgroundBlurRadiusFunc = @convention(c) (Int32, Int, Int) -> Int32

    private static let skyLightHandle: UnsafeMutableRawPointer? = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW)
    private static let mainConnFunc: CGSMainConnectionIDFunc? = {
        guard let handle = skyLightHandle,
              let sym = dlsym(handle, "CGSMainConnectionID") else { return nil }
        return unsafeBitCast(sym, to: CGSMainConnectionIDFunc.self)
    }()
    private static let setBlurFunc: SLSSetWindowBackgroundBlurRadiusFunc? = {
        guard let handle = skyLightHandle,
              let sym = dlsym(handle, "SLSSetWindowBackgroundBlurRadius") else { return nil }
        return unsafeBitCast(sym, to: SLSSetWindowBackgroundBlurRadiusFunc.self)
    }()

    public init(screen: NSScreen) {
        let frame = screen.frame
        self.blurView = BlurOverlayView(frame: NSRect(origin: .zero, size: frame.size))

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.animationBehavior = .none
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        contentView = blurView

        // Apply hardware compositor blur via SkyLight if available
        applySkyLightBlur(radius: 40)
    }

    public func applySkyLightBlur(radius: Int) {
        guard let mainConn = Self.mainConnFunc,
              let setBlur = Self.setBlurFunc else { return }
        let cid = mainConn()
        _ = setBlur(cid, self.windowNumber, radius)
    }

    public func update(fraction: Double, side: BlurSide, style: BlurStyle, featherWidth: Double) {
        blurView.update(fraction: fraction, side: side, style: style, featherWidth: featherWidth)
    }
}
