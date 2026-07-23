import CoreGraphics

/// Pure zoom math (M3.1). Given a scale and the point to zoom about (the
/// cursor), produces the affine transform that magnifies content while keeping
/// that point fixed — so the pixel under the cursor stays under the cursor.
/// Kept free of any view/window dependency so the geometry is unit-tested in
/// isolation; `OverlayWindow` applies the transform to place the magnified
/// image. Panning (M3.2) and variable zoom (M3.3) build on this.
enum ZoomRenderer {
  /// The zoom level applied on activation, per docs/spec.md §3.
  static let defaultScale: CGFloat = 2

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
