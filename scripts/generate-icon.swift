#!/usr/bin/env swift
// Generates AppIcon.icns — a coffee cup with steam on a rounded-rect background
import AppKit

func drawIcon(size: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // Background: rounded rect with a warm gradient
        let cornerRadius = size * 0.22
        let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                                   xRadius: cornerRadius, yRadius: cornerRadius)

        // Gradient: warm teal/green
        let topColor = NSColor(calibratedRed: 0.25, green: 0.72, blue: 0.65, alpha: 1.0)
        let bottomColor = NSColor(calibratedRed: 0.18, green: 0.55, blue: 0.50, alpha: 1.0)
        let gradient = NSGradient(starting: bottomColor, ending: topColor)!
        gradient.draw(in: bgPath, angle: 90)

        // Cup body centered in icon; handle extends to the right
        let cupWidth = size * 0.40
        let cx = size * 0.50
        let cl = cx - cupWidth / 2
        let cr = cx + cupWidth / 2
        let cupBottom = size * 0.18
        let cupTop = size * 0.55

        let handleExtend = size * 0.14
        let handleLineWidth = size * 0.038

        // Subtle shadow under the cup+handle
        let shadowColor = NSColor(white: 0, alpha: 0.15)
        shadowColor.setFill()
        let shadowRect = NSRect(x: cl - size * 0.03, y: size * 0.15,
                                width: cupWidth + size * 0.06, height: size * 0.04)
        NSBezierPath(ovalIn: shadowRect).fill()

        let white = NSColor.white

        // Draw handle FIRST, then cup body on top — cup covers the join, no seam
        let hAttachTop = cupTop - size * 0.04
        let hAttachBottom = cupBottom + size * 0.10
        let hMidY = (hAttachTop + hAttachBottom) / 2
        white.setStroke()
        let handlePath = NSBezierPath()
        let hx = cr - size * 0.03  // shift handle left into the cup wall
        handlePath.move(to: NSPoint(x: hx, y: hAttachTop))
        handlePath.curve(to: NSPoint(x: hx, y: hAttachBottom),
                         controlPoint1: NSPoint(x: hx + handleExtend, y: hMidY + (hAttachTop - hMidY) * 0.6),
                         controlPoint2: NSPoint(x: hx + handleExtend, y: hMidY + (hAttachBottom - hMidY) * 0.6))
        handlePath.lineWidth = handleLineWidth
        handlePath.lineCapStyle = .round
        handlePath.stroke()

        // Cup body — drawn after handle so it covers the join points
        white.setFill()
        let cupPath = NSBezierPath()
        let taperInset = cupWidth * 0.08
        cupPath.move(to: NSPoint(x: cl, y: cupTop))
        cupPath.line(to: NSPoint(x: cl + taperInset, y: cupBottom + size * 0.03))
        cupPath.curve(to: NSPoint(x: cr - taperInset, y: cupBottom + size * 0.03),
                      controlPoint1: NSPoint(x: cl + taperInset, y: cupBottom - size * 0.01),
                      controlPoint2: NSPoint(x: cr - taperInset, y: cupBottom - size * 0.01))
        cupPath.line(to: NSPoint(x: cr, y: cupTop))
        cupPath.close()
        cupPath.fill()

        // Cup rim (slightly wider than cup body)
        let rimHeight = size * 0.03
        let rimPath = NSBezierPath(roundedRect: NSRect(x: cl - size * 0.02, y: cupTop,
                                                        width: cupWidth + size * 0.04, height: rimHeight),
                                    xRadius: rimHeight / 2, yRadius: rimHeight / 2)
        rimPath.fill()

        // Steam — three wavy lines above the cup, centered on cup body
        let steamColor = NSColor(white: 1.0, alpha: 0.7)
        steamColor.setStroke()

        let steamBaseY = cupTop + rimHeight + size * 0.04
        let steamTopY = size * 0.82
        let steamXPositions = [cx - cupWidth * 0.25,
                               cx,
                               cx + cupWidth * 0.25]

        for (i, sx) in steamXPositions.enumerated() {
            let steam = NSBezierPath()
            let amplitude = size * 0.035
            let phase: CGFloat = i % 2 == 0 ? 1.0 : -1.0
            let height = steamTopY - steamBaseY
            steam.move(to: NSPoint(x: sx, y: steamBaseY))
            steam.curve(to: NSPoint(x: sx, y: steamBaseY + height * 0.5),
                        controlPoint1: NSPoint(x: sx + amplitude * phase, y: steamBaseY + height * 0.15),
                        controlPoint2: NSPoint(x: sx - amplitude * phase, y: steamBaseY + height * 0.35))
            steam.curve(to: NSPoint(x: sx, y: steamTopY),
                        controlPoint1: NSPoint(x: sx + amplitude * phase, y: steamBaseY + height * 0.65),
                        controlPoint2: NSPoint(x: sx - amplitude * phase, y: steamBaseY + height * 0.85))
            steam.lineWidth = size * 0.022
            steam.lineCapStyle = .round
            steam.stroke()
        }

        return true
    }
}

// Generate all required sizes for .icns
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

// Create temporary iconset directory
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: tempDir)
try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

for (size, name) in sizes {
    let image = drawIcon(size: size)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create \(name)")
        continue
    }
    let fileURL = tempDir.appendingPathComponent("\(name).png")
    try pngData.write(to: fileURL)
}

// Convert iconset to icns using iconutil
let outputPath = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "BreakTime/Resources/AppIcon.icns")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempDir.path, "-o", outputPath.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("Icon generated at: \(outputPath.path)")
} else {
    print("iconutil failed with status \(process.terminationStatus)")
    exit(1)
}

// Cleanup
try? FileManager.default.removeItem(at: tempDir)
