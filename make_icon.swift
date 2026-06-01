import Cocoa

// Renders the app icon: a blue gradient rounded-square with a white paperclip.
// Outputs all sizes required for an .iconset, then we run iconutil to make .icns.

func tinted(_ image: NSImage, _ color: NSColor) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    let r = NSRect(origin: .zero, size: image.size)
    image.draw(at: .zero, from: r, operation: .sourceOver, fraction: 1)
    color.set()
    r.fill(using: .sourceAtop) // tints only the symbol's non-transparent pixels
    out.unlockFocus()
    return out
}

func render(px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(px)
    let inset = size * 0.06
    let bg = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let path = NSBezierPath(roundedRect: bg, xRadius: size * 0.225, yRadius: size * 0.225)
    let grad = NSGradient(colors: [
        NSColor(srgbRed: 0.30, green: 0.62, blue: 0.99, alpha: 1),
        NSColor(srgbRed: 0.11, green: 0.34, blue: 0.85, alpha: 1)
    ])!
    grad.draw(in: path, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: size * 0.46, weight: .bold)
    if let base = NSImage(systemSymbolName: "paperclip", accessibilityDescription: nil),
       let sym = base.withSymbolConfiguration(config) {
        let white = tinted(sym, .white)
        let ss = white.size
        let drawRect = NSRect(x: (size - ss.width) / 2, y: (size - ss.height) / 2,
                              width: ss.width, height: ss.height)
        white.draw(in: drawRect, from: NSRect(origin: .zero, size: ss),
                   operation: .sourceOver, fraction: 1)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// (filename, pixel size) — the standard macOS iconset set.
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),     ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),     ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),  ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),  ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),  ("icon_512x512@2x.png", 1024),
]
for (name, px) in sizes {
    let data = render(px: px)
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("  wrote \(name) (\(px)px)")
}
print("iconset ready at \(outDir)")
