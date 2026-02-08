import Cocoa
import CoreGraphics

let width: CGFloat = 600
let height: CGFloat = 400
let size = NSSize(width: width, height: height)

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(width),
    pixelsHigh: Int(height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let context = NSGraphicsContext.current!.cgContext
let gradientColors = [
    NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0).cgColor,
    NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
]
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: gradientColors as CFArray,
    locations: [0.0, 1.0]
)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: height),
    end: CGPoint(x: 0, y: 0),
    options: []
)

// Title - Deep blue
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
    .foregroundColor: NSColor(red: 0.118, green: 0.227, blue: 0.541, alpha: 1.0)
]
let title = NSAttributedString(string: "OpenClawKit", attributes: titleAttrs)
title.draw(at: NSPoint(x: 200, y: 350))

// Subtitle - Gray (visible on light background)
let subtitleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14),
    .foregroundColor: NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
]
let subtitle = NSAttributedString(string: "AI Assistant Installer for macOS", attributes: subtitleAttrs)
subtitle.draw(at: NSPoint(x: 175, y: 320))

// Arrow pointing right - below icons
let arrowAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
]
let step1 = NSAttributedString(string: "Drag to Applications →", attributes: arrowAttrs)
step1.draw(at: NSPoint(x: 220, y: 140))

NSGraphicsContext.restoreGraphicsState()

if let data = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "assets/dmg-background.png")
    try? data.write(to: url)
    print("✅ Created assets/dmg-background.png")
}
