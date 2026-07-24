#!/usr/bin/env swift
import AppKit

// Regenerates XPlain's app icon + menu-bar template PNGs into the asset catalog
// (M6.6). Run: swift scripts/generate-icons.swift. The Contents.json files are
// checked in; this only rewrites the images so the icon is reproducible.

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Sources/XPlain/Assets.xcassets")
let appIconDir = assets.appendingPathComponent("AppIcon.appiconset")
let menuBarDir = assets.appendingPathComponent("MenuBarIcon.imageset")

func save(_ image: NSImage, pixels: Int, to url: URL) {
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  rep.size = NSSize(width: pixels, height: pixels)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  image.draw(
    in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
    from: .zero, operation: .sourceOver, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()
  try? rep.representation(using: .png, properties: [:])!.write(to: url)
}

/// A magnifying glass (lens + handle), optionally with a "+" to imply zoom.
func magnifier(in size: CGFloat, color: NSColor, lineWidth: CGFloat, plus: Bool) {
  let lensRadius = size * 0.26
  let center = CGPoint(x: size * 0.44, y: size * 0.56)
  color.setStroke()
  color.setFill()

  let lens = NSBezierPath(
    ovalIn: NSRect(
      x: center.x - lensRadius, y: center.y - lensRadius,
      width: lensRadius * 2, height: lensRadius * 2))
  lens.lineWidth = lineWidth
  lens.stroke()

  // Handle: from the lower-right of the lens, angled 45° outward.
  let angle = CGFloat.pi * 1.75
  let start = CGPoint(x: center.x + cos(angle) * lensRadius, y: center.y + sin(angle) * lensRadius)
  let end = CGPoint(
    x: center.x + cos(angle) * (lensRadius + size * 0.22),
    y: center.y + sin(angle) * (lensRadius + size * 0.22))
  let handle = NSBezierPath()
  handle.move(to: start)
  handle.line(to: end)
  handle.lineWidth = lineWidth * 1.15
  handle.lineCapStyle = .round
  handle.stroke()

  if plus {
    let arm = lensRadius * 0.55
    let bar = lineWidth * 0.9
    let plusPath = NSBezierPath()
    plusPath.move(to: CGPoint(x: center.x - arm, y: center.y))
    plusPath.line(to: CGPoint(x: center.x + arm, y: center.y))
    plusPath.move(to: CGPoint(x: center.x, y: center.y - arm))
    plusPath.line(to: CGPoint(x: center.x, y: center.y + arm))
    plusPath.lineWidth = bar
    plusPath.lineCapStyle = .round
    plusPath.stroke()
  }
}

func appIcon(size: CGFloat) -> NSImage {
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  let margin = size * 0.10
  let rect = NSRect(x: margin, y: margin, width: size - margin * 2, height: size - margin * 2)
  let radius = rect.width * 0.2237
  let shape = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

  let gradient = NSGradient(
    colors: [
      NSColor(calibratedRed: 0.31, green: 0.76, blue: 0.97, alpha: 1),  // light blue
      NSColor(calibratedRed: 0.08, green: 0.36, blue: 0.80, alpha: 1),  // deep blue
    ])!
  gradient.draw(in: shape, angle: -90)

  // Center the magnifier within the rounded-rect art area.
  NSGraphicsContext.current?.saveGraphicsState()
  let transform = AffineTransform(translationByX: rect.minX, byY: rect.minY)
  (transform as NSAffineTransform).concat()
  magnifier(in: rect.width, color: .white, lineWidth: rect.width * 0.075, plus: true)
  NSGraphicsContext.current?.restoreGraphicsState()

  image.unlockFocus()
  return image
}

func menuBarIcon(size: CGFloat) -> NSImage {
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  magnifier(in: size, color: .black, lineWidth: size * 0.10, plus: false)
  image.unlockFocus()
  return image
}

// App icon: the macOS set (16→1024, with @2x sharing).
for pixels in [16, 32, 64, 128, 256, 512, 1024] {
  save(
    appIcon(size: CGFloat(pixels)), pixels: pixels,
    to: appIconDir.appendingPathComponent("icon_\(pixels).png"))
}

// Menu-bar template: 18pt @1x/@2x/@3x.
save(menuBarIcon(size: 18), pixels: 18, to: menuBarDir.appendingPathComponent("menubar_18.png"))
save(menuBarIcon(size: 36), pixels: 36, to: menuBarDir.appendingPathComponent("menubar_36.png"))
save(menuBarIcon(size: 54), pixels: 54, to: menuBarDir.appendingPathComponent("menubar_54.png"))

print("Icons written to \(assets.path)")
