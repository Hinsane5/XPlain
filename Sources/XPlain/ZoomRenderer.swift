import CoreGraphics
import Foundation

/// Pure zoom math (M3.1). Given a scale and the point to zoom about (the
/// cursor), produces the affine transform that magnifies content while keeping
/// that point fixed — so the pixel under the cursor stays under the cursor.
/// Kept free of any view/window dependency so the geometry is unit-tested in
/// isolation; `OverlayWindow` applies the transform to place the magnified
/// image. Panning (M3.2) and variable zoom (M3.3) build on this.
enum ZoomRenderer {
  /// The zoom level applied on activation, per docs/spec.md §3.
  static let defaultScale: CGFloat = 2

  /// Zoom range and per-notch step (spec §3): 1.25×–8×, 0.25× per notch.
  static let minScale: CGFloat = 1.25
  static let maxScale: CGFloat = 8
  static let defaultStep: CGFloat = 0.25

  /// How long the zoom-in animates on entry (M3.4). `animated == false` (the
  /// Settings toggle, spec §7) gives 0 — a hard cut, no animation.
  static func entryAnimationDuration(animated: Bool) -> TimeInterval {
    animated ? 0.15 : 0
  }

  /// Clamps a scale into `[minScale, maxScale]`.
  static func clamped(_ scale: CGFloat) -> CGFloat {
    min(max(scale, minScale), maxScale)
  }

  /// The scale after `steps` notches (positive = zoom in), clamped to range.
  /// Both scroll and ↑/↓ funnel through this so they step identically (M3.3).
  static func zoomed(from scale: CGFloat, steps: Int, step: CGFloat = defaultStep) -> CGFloat {
    clamped(scale + CGFloat(steps) * step)
  }

  /// The "zoom about a point" transform: `p' = point + scale · (p − point)`.
  /// `point` is a fixed point (maps to itself); everything else moves `scale`×
  /// farther from it. Applying it to the display rect gives the magnified
  /// image view's frame, re-anchored so `point` stays put.
  static func transform(scale: CGFloat, about point: CGPoint) -> CGAffineTransform {
    CGAffineTransform(
      a: scale,
      b: 0,
      c: 0,
      d: scale,
      tx: point.x * (1 - scale),
      ty: point.y * (1 - scale)
    )
  }
}
