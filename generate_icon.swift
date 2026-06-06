import Foundation
import CoreGraphics
import ImageIO

// Pure CoreGraphics drawing script that runs headless without AppKit window-server dependencies.

func drawAppIcon(size: Int) -> CGContext? {
    let width = size
    let height = size
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo) else {
        return nil
    }
    
    let sizeF = CGFloat(size)
    
    // Clear context
    context.clear(CGRect(x: 0, y: 0, width: sizeF, height: sizeF))
    
    // Draw background: Dark, sleek rounded rectangle (squircle style)
    let margin = sizeF * 0.08
    let rect = CGRect(x: margin, y: margin, width: sizeF - 2 * margin, height: sizeF - 2 * margin)
    let cornerRadius = sizeF * 0.22
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Fill background with a beautiful dark metallic gradient
    let bgColors = [
        CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1.0),
        CGColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0)
    ] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: locations) {
        context.saveGState()
        context.addPath(bgPath)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: sizeF), end: CGPoint(x: 0, y: 0), options: [])
        context.restoreGState()
    }
    
    // Outer Sleek Neon Cyan-Green border
    context.saveGState()
    context.addPath(bgPath)
    context.setLineWidth(sizeF * 0.015)
    context.setStrokeColor(CGColor(red: 0.0, green: 0.8, blue: 0.6, alpha: 0.8))
    context.setShadow(offset: .zero, blur: sizeF * 0.02, color: CGColor(red: 0.0, green: 0.8, blue: 0.6, alpha: 0.5))
    context.strokePath()
    context.restoreGState()
    
    // Draw toggle switch track (pill shape) in center
    let trackW = sizeF * 0.38
    let trackH = sizeF * 0.18
    let trackX = (sizeF - trackW) / 2
    let trackY = (sizeF - trackH) / 2
    let trackRect = CGRect(x: trackX, y: trackY, width: trackW, height: trackH)
    let trackPath = CGPath(roundedRect: trackRect, cornerWidth: trackH / 2, cornerHeight: trackH / 2, transform: nil)
    
    context.saveGState()
    context.addPath(trackPath)
    // Dark green track background signifying "standby active"
    context.setFillColor(CGColor(red: 0.04, green: 0.18, blue: 0.14, alpha: 1.0))
    context.fillPath()
    
    context.addPath(trackPath)
    context.setLineWidth(sizeF * 0.008)
    context.setStrokeColor(CGColor(red: 0.0, green: 0.6, blue: 0.4, alpha: 0.6))
    context.strokePath()
    context.restoreGState()
    
    // Draw toggle knob on the right side (representing the "ON" state)
    let knobDiameter = trackH * 0.82
    let knobX = trackX + trackW - knobDiameter - (trackH - knobDiameter) / 2
    let knobY = trackY + (trackH - knobDiameter) / 2
    let knobRect = CGRect(x: knobX, y: knobY, width: knobDiameter, height: knobDiameter)
    let knobPath = CGPath(ellipseIn: knobRect, transform: nil)
    
    // Fill knob with a glowing AI green gradient
    let knobColors = [
        CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 1.0),
        CGColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1.0)
    ] as CFArray
    if let knobGradient = CGGradient(colorsSpace: colorSpace, colors: knobColors, locations: [0.0, 1.0]) {
        context.saveGState()
        context.addPath(knobPath)
        context.clip()
        context.drawLinearGradient(knobGradient, start: CGPoint(x: 0, y: knobY + knobDiameter), end: CGPoint(x: 0, y: knobY), options: [])
        context.restoreGState()
    }
    
    // Knob stroke and glow effect
    context.saveGState()
    context.addPath(knobPath)
    context.setLineWidth(sizeF * 0.005)
    context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    context.setShadow(offset: .zero, blur: sizeF * 0.03, color: CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 0.8))
    context.strokePath()
    context.restoreGState()
    
    // Draw minimalist power/switch symbol in knob center (dark contrast)
    let centerIconSize = knobDiameter * 0.42
    let centerIconRect = CGRect(x: knobX + (knobDiameter - centerIconSize)/2, y: knobY + (knobDiameter - centerIconSize)/2, width: centerIconSize, height: centerIconSize)
    let centerPoint = CGPoint(x: centerIconRect.midX, y: centerIconRect.midY)
    let radius = centerIconSize / 2
    
    context.saveGState()
    context.setLineWidth(sizeF * 0.008)
    context.setLineCap(.round)
    context.setStrokeColor(CGColor(red: 0.04, green: 0.18, blue: 0.14, alpha: 0.95))
    
    // Power Arc
    context.addArc(center: centerPoint, radius: radius, startAngle: CGFloat.pi * 0.22, endAngle: CGFloat.pi * 0.78, clockwise: true)
    context.strokePath()
    
    // Power Line
    context.move(to: CGPoint(x: centerPoint.x, y: centerPoint.y - radius * 0.35))
    context.addLine(to: CGPoint(x: centerPoint.x, y: centerPoint.y + radius * 0.85))
    context.strokePath()
    context.restoreGState()
    
    // Draw indicators on the left side of track
    let dotRadius = sizeF * 0.012
    let dot1Rect = CGRect(x: trackX + trackH/2 - dotRadius, y: trackY + trackH/2 - dotRadius, width: dotRadius*2, height: dotRadius*2)
    context.saveGState()
    context.setFillColor(CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 0.3))
    context.setShadow(offset: .zero, blur: sizeF * 0.01, color: CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 0.6))
    context.fillEllipse(in: dot1Rect)
    context.restoreGState()
    
    return context
}

func drawStatusIcon(size: Int, state: Int) -> CGContext? {
    let width = size
    let height = size
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo) else {
        return nil
    }
    
    let sizeF = CGFloat(size)
    context.clear(CGRect(x: 0, y: 0, width: sizeF, height: sizeF))
    
    // Track sizing (scaled for standard macOS menu bar height which is 22pt)
    let trackW = sizeF * 0.82
    let trackH = sizeF * 0.44
    let trackX = (sizeF - trackW) / 2
    let trackY = (sizeF - trackH) / 2
    
    let trackPath = CGPath(roundedRect: CGRect(x: trackX, y: trackY, width: trackW, height: trackH),
                           cornerWidth: trackH / 2,
                           cornerHeight: trackH / 2,
                           transform: nil)
    
    context.saveGState()
    context.addPath(trackPath)
    if state == 2 {
        // Connected: Dark green track background
        context.setFillColor(CGColor(red: 0.05, green: 0.22, blue: 0.16, alpha: 1.0))
    } else if state == 1 {
        // Connecting: Dark yellow track background
        context.setFillColor(CGColor(red: 0.20, green: 0.16, blue: 0.05, alpha: 1.0))
    } else {
        // Inactive: Dark red track background
        context.setFillColor(CGColor(red: 0.22, green: 0.08, blue: 0.08, alpha: 1.0))
    }
    context.fillPath()
    
    // Track stroke
    context.addPath(trackPath)
    context.setLineWidth(sizeF * 0.04)
    if state == 2 {
        context.setStrokeColor(CGColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 0.6))
    } else if state == 1 {
        context.setStrokeColor(CGColor(red: 0.7, green: 0.5, blue: 0.1, alpha: 0.6))
    } else {
        context.setStrokeColor(CGColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 0.6))
    }
    context.strokePath()
    context.restoreGState()
    
    // Knob sizing
    let knobDiameter = trackH * 0.84
    let knobY = trackY + (trackH - knobDiameter) / 2
    
    let knobX: CGFloat
    if state == 2 {
        // Right side
        knobX = trackX + trackW - knobDiameter - (trackH - knobDiameter) / 2
    } else if state == 1 {
        // Middle position
        knobX = trackX + (trackW - knobDiameter) / 2
    } else {
        // Left side
        knobX = trackX + (trackH - knobDiameter) / 2
    }
    
    let knobRect = CGRect(x: knobX, y: knobY, width: knobDiameter, height: knobDiameter)
    let knobPath = CGPath(ellipseIn: knobRect, transform: nil)
    
    // Fill knob with gradient (Green for active, Yellow for connecting, Red for inactive)
    let knobColors: CFArray
    if state == 2 {
        knobColors = [
            CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 1.0),
            CGColor(red: 0.0, green: 0.7, blue: 0.5, alpha: 1.0)
        ] as CFArray
    } else if state == 1 {
        knobColors = [
            CGColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1.0),
            CGColor(red: 0.8, green: 0.5, blue: 0.0, alpha: 1.0)
        ] as CFArray
    } else {
        knobColors = [
            CGColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
            CGColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
        ] as CFArray
    }
    
    if let knobGradient = CGGradient(colorsSpace: colorSpace, colors: knobColors, locations: [0.0, 1.0]) {
        context.saveGState()
        context.addPath(knobPath)
        context.clip()
        context.drawLinearGradient(knobGradient, start: CGPoint(x: 0, y: knobY + knobDiameter), end: CGPoint(x: 0, y: knobY), options: [])
        context.restoreGState()
    }
    
    // Knob stroke & glow
    context.saveGState()
    context.addPath(knobPath)
    context.setLineWidth(sizeF * 0.02)
    context.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    if state == 2 {
        context.setShadow(offset: .zero, blur: sizeF * 0.06, color: CGColor(red: 0.0, green: 1.0, blue: 0.7, alpha: 0.8))
    } else if state == 1 {
        context.setShadow(offset: .zero, blur: sizeF * 0.06, color: CGColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 0.8))
    } else {
        context.setShadow(offset: .zero, blur: sizeF * 0.06, color: CGColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.8))
    }
    context.strokePath()
    context.restoreGState()
    
    return context
}

func saveContextToPNG(context: CGContext, url: URL) {
    guard let image = context.makeImage() else {
        print("Error: Failed to create CGImage from context")
        return
    }
    
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        print("Error: Failed to create image destination")
        return
    }
    
    CGImageDestinationAddImage(destination, image, nil)
    if CGImageDestinationFinalize(destination) {
        print("Saved: \(url.lastPathComponent)")
    } else {
        print("Error: Failed to finalize PNG destination")
    }
}

// 1. Generate AppIcon PNGs
let sizes = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_64x64.png", 64),
    ("icon_64x64@2x.png", 128),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let fileManager = FileManager.default
let iconsetPath = "AppIcon.iconset"

do {
    try fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
    print("Generating app icon PNG sizes into \(iconsetPath)...")
    for (filename, size) in sizes {
        let fileURL = URL(fileURLWithPath: iconsetPath).appendingPathComponent(filename)
        if let context = drawAppIcon(size: size) {
            saveContextToPNG(context: context, url: fileURL)
        }
    }
} catch {
    print("Error generating app icon: \(error)")
    exit(1)
}

// 2. Generate Menu Bar Status Switch PNGs
print("Generating menu bar status icons...")
let statusGreen1x = drawStatusIcon(size: 20, state: 2)
let statusGreen2x = drawStatusIcon(size: 40, state: 2)
let statusYellow1x = drawStatusIcon(size: 20, state: 1)
let statusYellow2x = drawStatusIcon(size: 40, state: 1)
let statusRed1x = drawStatusIcon(size: 20, state: 0)
let statusRed2x = drawStatusIcon(size: 40, state: 0)

if let ctx = statusGreen1x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_green.png")) }
if let ctx = statusGreen2x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_green@2x.png")) }
if let ctx = statusYellow1x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_yellow.png")) }
if let ctx = statusYellow2x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_yellow@2x.png")) }
if let ctx = statusRed1x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_red.png")) }
if let ctx = statusRed2x { saveContextToPNG(context: ctx, url: URL(fileURLWithPath: "status_red@2x.png")) }

print("All icons generated successfully.")
