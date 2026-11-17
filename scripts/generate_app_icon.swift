import AppKit
import Foundation

// Original CarOs icon. Runs on the macOS Xcode runner before building.
// Intentionally exports opaque RGB PNG (Apple App Store requires no alpha).
// Render in RGBA (supported by headless macOS NSGraphicsContext) and convert
// through JPEG to remove the alpha channel before writing the final PNG.
let dimension = 1024
guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: dimension, pixelsHigh: dimension,
  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
  isPlanar: false, colorSpaceName: .deviceRGB,
  bytesPerRow: 4096, bitsPerPixel: 32
), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
  fatalError("Cannot create RGB icon bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

func fill(_ path: NSBezierPath, _ color: NSColor) {
  color.setFill()
  path.fill()
}

fill(NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)),
     NSColor(calibratedRed: 0.025, green: 0.065, blue: 0.13, alpha: 1))

// Three layered panels form a stylized infotainment dashboard.
fill(NSBezierPath(roundedRect: NSRect(x: 100, y: 130, width: 824, height: 764),
                  xRadius: 170, yRadius: 170),
     NSColor(calibratedRed: 0.08, green: 0.20, blue: 0.38, alpha: 1))
fill(NSBezierPath(roundedRect: NSRect(x: 160, y: 275, width: 704, height: 520),
                  xRadius: 95, yRadius: 95),
     NSColor(calibratedRed: 0.025, green: 0.12, blue: 0.26, alpha: 1))
fill(NSBezierPath(roundedRect: NSRect(x: 206, y: 328, width: 612, height: 412),
                  xRadius: 72, yRadius: 72),
     NSColor(calibratedRed: 0.055, green: 0.29, blue: 0.51, alpha: 1))

// Rounded stylized C and play glyph — not copied from a trademark.
let c = NSBezierPath()
c.lineWidth = 50
c.lineCapStyle = .round
c.appendArc(withCenter: NSPoint(x: 481, y: 530), radius: 143,
            startAngle: 48, endAngle: 310, clockwise: false)
NSColor(calibratedRed: 0.98, green: 0.99, blue: 1, alpha: 1).setStroke()
c.stroke()

let triangle = NSBezierPath()
triangle.move(to: NSPoint(x: 540, y: 480))
triangle.line(to: NSPoint(x: 540, y: 582))
triangle.line(to: NSPoint(x: 632, y: 530))
triangle.close()
fill(triangle, NSColor(calibratedRed: 0.25, green: 0.95, blue: 0.83, alpha: 1))

// Dashboard dots.
for (index, color) in [
  NSColor(calibratedRed: 0.25, green: 0.95, blue: 0.83, alpha: 1),
  NSColor(calibratedRed: 0.42, green: 0.69, blue: 0.99, alpha: 1),
  NSColor(calibratedRed: 0.95, green: 0.48, blue: 0.40, alpha: 1)
].enumerated() {
  fill(NSBezierPath(ovalIn: NSRect(x: 427 + 58 * index, y: 218, width: 28, height: 28)), color)
}

NSGraphicsContext.restoreGraphicsState()

let file = URL(fileURLWithPath: "CafariLite/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
guard let flattened = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.99]),
      let opaque = NSBitmapImageRep(data: flattened),
      let png = opaque.representation(using: .png, properties: [:]) else {
  fatalError("Could not encode opaque AppIcon.png")
}
try png.write(to: file, options: .atomic)
print("Generated opaque RGB CarOs AppIcon.png (1024 x 1024)")
