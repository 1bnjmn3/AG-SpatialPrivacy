import Cocoa

// Generate icon image
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Rounded squircle background (macOS Big Sur style)
let rect = CGRect(x: 80, y: 80, width: 864, height: 864)
let path = CGPath(roundedRect: rect, cornerWidth: 200, cornerHeight: 200, transform: nil)

// Dark frosted gradient background
let colorSpace = CGColorSpaceCreateDeviceRGB()
let colors = [
    NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).cgColor,
    NSColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1.0).cgColor
] as CFArray
if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
    ctx.restoreGState()
}

// Subtle border
ctx.saveGState()
ctx.addPath(path)
ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.15).cgColor)
ctx.setLineWidth(10)
ctx.strokePath()
ctx.restoreGState()

// Draw Shield Symbol
let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .semibold)
if let shield = NSImage(systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    let shieldRect = NSRect(x: (size - 440) / 2, y: (size - 440) / 2 - 10, width: 440, height: 440)
    shield.draw(in: shieldRect)
}

// Spatial blur glow arc
ctx.saveGState()
ctx.setStrokeColor(NSColor.systemCyan.withAlphaComponent(0.6).cgColor)
ctx.setLineWidth(16)
ctx.setLineCap(.round)
ctx.addArc(center: CGPoint(x: 512, y: 500), radius: 280, startAngle: -.pi * 0.25, endAngle: .pi * 0.25, clockwise: false)
ctx.strokePath()
ctx.restoreGState()

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    exit(1)
}

let iconsetURL = URL(fileURLWithPath: "Resources/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    let resized = NSImage(size: NSSize(width: s, height: s))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: s, height: s))
    resized.unlockFocus()
    if let rep = NSBitmapImageRep(data: resized.tiffRepresentation!),
       let data = rep.representation(using: .png, properties: [:]) {
        let dest = iconsetURL.appendingPathComponent("icon_\(s)x\(s).png")
        try? data.write(to: dest)
        if s <= 512 {
            let dest2x = iconsetURL.appendingPathComponent("icon_\(s/2)x\(s/2)@2x.png")
            try? data.write(to: dest2x)
        }
    }
}
print("Iconset created successfully")
