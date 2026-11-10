import AppKit

/// Menu bar glyph: an iPhone outline with connection arcs. Drawn as a template image so macOS
/// tints it for light/dark menu bars. `busy` fills the screen to show an action is running.
enum MenuBarIcon {
    static let idle = make(busy: false)
    static let busy = make(busy: true)

    private static func make(busy: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            // Tall phone using nearly the full menu bar height.
            let phone = NSBezierPath(roundedRect: NSRect(x: 3.5, y: 0.75, width: 11, height: 16.5),
                                     xRadius: 3, yRadius: 3)
            phone.lineWidth = 1.5
            phone.stroke()
            if busy {
                NSBezierPath(roundedRect: NSRect(x: 5.5, y: 2.75, width: 7, height: 12.5),
                             xRadius: 1.6, yRadius: 1.6).fill()
            } else {
                // Small connection arcs, kept clear of the outline.
                let c = NSPoint(x: 9, y: 6.2)
                NSBezierPath(ovalIn: NSRect(x: c.x - 1, y: c.y - 1, width: 2, height: 2)).fill()
                for r in [2.6, 4.4] {
                    let arc = NSBezierPath()
                    arc.appendArc(withCenter: c, radius: r, startAngle: 50, endAngle: 130)
                    arc.lineWidth = 1.2
                    arc.lineCapStyle = .round
                    arc.stroke()
                }
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = busy ? "DeviceBar, working" : "DeviceBar"
        return image
    }
}
