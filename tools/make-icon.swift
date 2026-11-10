// Generates Resources/AppIcon.icns (run: swift tools/make-icon.swift).
import AppKit

let size: CGFloat = 1024

func render(into ctx: CGContext) {
    // macOS icon grid: 824pt rounded body centred in 1024pt canvas.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    // Soft drop shadow under the body.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28,
                  color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(bodyPath)
    ctx.setFillColor(CGColor(gray: 0.1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Background gradient (top: light blue, bottom: indigo).
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let cs = CGColorSpaceCreateDeviceRGB()
    let grad = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.36, green: 0.62, blue: 1.00, alpha: 1),
        CGColor(red: 0.30, green: 0.28, blue: 0.86, alpha: 1),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    // Menu bar strip along the top of the icon.
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.16))
    ctx.fill(CGRect(x: 100, y: 924 - 96, width: 824, height: 96))
    // Little dots on the strip, like menu bar items.
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.85))
    for i in 0..<3 {
        let r = CGRect(x: 790 - CGFloat(i) * 62, y: 924 - 60, width: 28, height: 24)
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 8, cornerHeight: 8, transform: nil))
        ctx.fillPath()
    }
    ctx.restoreGState()

    // iPhone: white body, dark screen, dynamic island.
    let phone = CGRect(x: 342, y: 190, width: 340, height: 600)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: CGColor(gray: 0, alpha: 0.30))
    ctx.addPath(CGPath(roundedRect: phone, cornerWidth: 62, cornerHeight: 62, transform: nil))
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    let screen = phone.insetBy(dx: 18, dy: 18)
    ctx.addPath(CGPath(roundedRect: screen, cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.setFillColor(CGColor(red: 0.07, green: 0.08, blue: 0.18, alpha: 1))
    ctx.fillPath()

    let island = CGRect(x: screen.midX - 38, y: screen.maxY - 42, width: 76, height: 22)
    ctx.addPath(CGPath(roundedRect: island, cornerWidth: 11, cornerHeight: 11, transform: nil))
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()

    // Connection arcs on the screen (device is "driven" from the Mac).
    ctx.setStrokeColor(CGColor(red: 0.45, green: 0.78, blue: 1.0, alpha: 1))
    ctx.setLineCap(.round)
    ctx.setLineWidth(22)
    let center = CGPoint(x: screen.midX, y: screen.midY - 70)
    for (i, radius) in [44.0, 96.0, 148.0].enumerated() {
        ctx.setAlpha(1.0 - CGFloat(i) * 0.25)
        ctx.addArc(center: center, radius: radius, startAngle: .pi * 0.25, endAngle: .pi * 0.75, clockwise: false)
        ctx.strokePath()
    }
    ctx.setAlpha(1)
    ctx.setFillColor(CGColor(red: 0.45, green: 0.78, blue: 1.0, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext
    ctx.scaleBy(x: CGFloat(pixels) / size, y: CGFloat(pixels) / size)
    render(into: ctx)
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let set = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: set)
try FileManager.default.createDirectory(at: set, withIntermediateDirectories: true)
let specs: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in specs {
    try png(pixels: px).write(to: set.appendingPathComponent("\(name).png"))
}
try png(pixels: 1024).write(to: root.appendingPathComponent("build/AppIcon-preview.png"))
print("iconset ready")
