import Cocoa

guard let sourceImage = NSImage(contentsOfFile: "Resources/AppIcon_original.jpg") else {
    print("Could not load original image")
    exit(1)
}

let canvasSize: CGFloat = 1024
let finalImage = NSImage(size: NSSize(width: canvasSize, height: canvasSize))

finalImage.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// The squircle in the source image is at roughly (156, 156, 712, 712) in standard coords
// In macOS, icon standard canvas has the squircle inset to CGRect(x: 96, y: 96, width: 832, height: 832)
let destRect = CGRect(x: 96, y: 96, width: 832, height: 832)
let squirclePath = CGPath(roundedRect: destRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Draw subtle drop shadow below the squircle
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: NSColor.black.withAlphaComponent(0.45).cgColor)
ctx.addPath(squirclePath)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Clip to squircle path
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()

// Source squircle rect in image
// NSImage draw in rect from source rect (note: AppKit flipped coordinates)
let srcRect = NSRect(x: 154, y: 154, width: 716, height: 716)
sourceImage.draw(in: destRect, from: srcRect, operation: .copy, fraction: 1.0)
ctx.restoreGState()

finalImage.unlockFocus()

// Save high-res PNG
guard let tiff = finalImage.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    print("Failed to encode PNG")
    exit(1)
}

let appIconPNG = URL(fileURLWithPath: "Resources/AppIcon.png")
try? pngData.write(to: appIconPNG)

// Generate iconset
let iconsetDir = URL(fileURLWithPath: "Resources/AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (baseSize, scale) in sizes {
    let px = baseSize * scale
    let scaled = NSImage(size: NSSize(width: px, height: px))
    scaled.lockFocus()
    finalImage.draw(in: NSRect(x: 0, y: 0, width: px, height: px), from: .zero, operation: .copy, fraction: 1.0)
    scaled.unlockFocus()

    if let t = scaled.tiffRepresentation,
       let r = NSBitmapImageRep(data: t),
       let data = r.representation(using: .png, properties: [:]) {
        let name = scale == 1 ? "icon_\(baseSize)x\(baseSize).png" : "icon_\(baseSize)x\(baseSize)@2x.png"
        try? data.write(to: iconsetDir.appendingPathComponent(name))
    }
}

print("Iconset created successfully")
