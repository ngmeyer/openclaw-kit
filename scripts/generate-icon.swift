import Cocoa
import CoreGraphics

// OpenClawKit Brand Colors
let deepBlue = NSColor(red: 0.118, green: 0.227, blue: 0.541, alpha: 1.0)      // #1E3A8A
let vibrantCoral = NSColor(red: 0.984, green: 0.486, blue: 0.290, alpha: 1.0)   // #FB7C4A
let lightBlue = NSColor(red: 0.749, green: 0.820, blue: 1.0, alpha: 1.0)        // #BFD1FF
let white = NSColor.white

func generateIcon(size: CGFloat, filename: String) {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
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
    
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    
    // Draw rounded rect background with gradient
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Gradient from deep blue to slightly lighter blue
    let gradientColors = [
        deepBlue.cgColor,
        NSColor(red: 0.15, green: 0.28, blue: 0.65, alpha: 1.0).cgColor
    ]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: gradientColors as CFArray,
        locations: [0.0, 1.0]
    )!
    
    context.saveGState()
    path.addClip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
    context.restoreGState()
    
    // Draw "Kit" concept - a toolbox/package with gear
    let center = CGPoint(x: size / 2, y: size / 2)
    let boxSize = size * 0.55
    let boxRect = CGRect(
        x: center.x - boxSize / 2,
        y: center.y - boxSize / 2,
        width: boxSize,
        height: boxSize
    )
    
    // Draw box/toolkit shape
    let boxPath = NSBezierPath(roundedRect: boxRect, xRadius: size * 0.08, yRadius: size * 0.08)
    vibrantCoral.setFill()
    boxPath.fill()
    
    // Add a handle on top
    let handleWidth = boxSize * 0.4
    let handleHeight = size * 0.08
    let handleRect = CGRect(
        x: center.x - handleWidth / 2,
        y: center.y + boxSize / 2 - handleHeight / 2,
        width: handleWidth,
        height: handleHeight
    )
    let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: handleHeight / 2, yRadius: handleHeight / 2)
    white.setFill()
    handlePath.fill()
    
    // Add gear icon in center (representing setup/configuration)
    let gearCenter = CGPoint(x: center.x, y: center.y - boxSize * 0.05)
    let gearRadius = boxSize * 0.22
    let teeth = 8
    
    let gearPath = NSBezierPath()
    for i in 0..<teeth {
        let angle = Double(i) * 2.0 * .pi / Double(teeth)
        let nextAngle = Double(i + 1) * 2.0 * .pi / Double(teeth)
        
        let innerRadius = gearRadius * 0.6
        let outerRadius = gearRadius
        
        let x1 = gearCenter.x + CGFloat(cos(angle - 0.2)) * innerRadius
        let y1 = gearCenter.y + CGFloat(sin(angle - 0.2)) * innerRadius
        let x2 = gearCenter.x + CGFloat(cos(angle)) * outerRadius
        let y2 = gearCenter.y + CGFloat(sin(angle)) * outerRadius
        let x3 = gearCenter.x + CGFloat(cos(nextAngle - 0.5)) * outerRadius
        let y3 = gearCenter.y + CGFloat(sin(nextAngle - 0.5)) * outerRadius
        let x4 = gearCenter.x + CGFloat(cos(nextAngle - 0.3)) * innerRadius
        let y4 = gearCenter.y + CGFloat(sin(nextAngle - 0.3)) * innerRadius
        
        if i == 0 {
            gearPath.move(to: CGPoint(x: x1, y: y1))
        }
        gearPath.line(to: CGPoint(x: x2, y: y2))
        gearPath.line(to: CGPoint(x: x3, y: y3))
        gearPath.line(to: CGPoint(x: x4, y: y4))
    }
    gearPath.close()
    
    // Fill gear
    white.setFill()
    gearPath.fill()
    
    // Center circle in gear
    let centerCircle = NSBezierPath(ovalIn: CGRect(
        x: gearCenter.x - gearRadius * 0.25,
        y: gearCenter.y - gearRadius * 0.25,
        width: gearRadius * 0.5,
        height: gearRadius * 0.5
    ))
    vibrantCoral.setFill()
    centerCircle.fill()
    
    // Draw subtle border
    context.setStrokeColor(NSColor(red: 1, green: 1, blue: 1, alpha: 0.25).cgColor)
    context.setLineWidth(size * 0.015)
    context.stroke(rect.insetBy(dx: size * 0.03, dy: size * 0.03), width: cornerRadius * 0.8)
    
    NSGraphicsContext.restoreGraphicsState()
    
    if let data = bitmap.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: filename)
        try? data.write(to: url)
        print("✅ Created \(filename)")
    }
}

// Generate all required icon sizes
generateIcon(size: 16, filename: "assets/OpenClawKit.iconset/icon_16x16.png")
generateIcon(size: 32, filename: "assets/OpenClawKit.iconset/icon_16x16@2x.png")
generateIcon(size: 32, filename: "assets/OpenClawKit.iconset/icon_32x32.png")
generateIcon(size: 64, filename: "assets/OpenClawKit.iconset/icon_32x32@2x.png")
generateIcon(size: 128, filename: "assets/OpenClawKit.iconset/icon_128x128.png")
generateIcon(size: 256, filename: "assets/OpenClawKit.iconset/icon_128x128@2x.png")
generateIcon(size: 256, filename: "assets/OpenClawKit.iconset/icon_256x256.png")
generateIcon(size: 512, filename: "assets/OpenClawKit.iconset/icon_256x256@2x.png")
generateIcon(size: 512, filename: "assets/OpenClawKit.iconset/icon_512x512.png")
generateIcon(size: 1024, filename: "assets/OpenClawKit.iconset/icon_512x512@2x.png")

print("✅ All OpenClawKit branded icons generated")
