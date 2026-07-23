import CoreGraphics

/// Pure cursor-follow math for LiveZoom (M5.4). Given the live cursor and the
/// previous anchor, picks the next *anchor* — the display point the magnifier is
/// scaled about (fed to `ZoomRenderer.transform`). Kept free of any view/window
/// dependency so the geometry is unit-tested in isolation; `LiveZoomView` calls
/// it each frame and applies the transform.
enum LiveZoomFollow {
  /// How the magnified region tracks the cursor (spec §5). User-selectable via
  /// the status menu; persisted in `Preferences`.
  enum Mode: String, CaseIterable {
    /// The anchor is the cursor every frame — the magnified content re-centers
    /// on the pointer continuously (the default, matches static Zoom).
    case cursorCentered
    /// The view holds still while the cursor roams a central dead zone, and only
    /// scrolls once the cursor nears the edge — steadier for reading/demoing.
    case edgePush

    /// Human-readable label for the status-menu items.
    var title: String {
      switch self {
      case .cursorCentered: return "Cursor-centered"
      case .edgePush: return "Edge-push"
      }
    }
  }

  /// The fraction of the view half-extent the cursor may roam, in edge-push,
  /// before the anchor starts trailing it. 0.5 → a dead zone half the size of
  /// the view, centered on the anchor.
  static let edgePushDeadZoneFraction: CGFloat = 0.5

  /// The edge-push dead-zone half-width for a view of the given width. The
  /// cursor can move this far from the anchor (in x) before the view scrolls.
  static func edgePushDeadZone(width: CGFloat) -> CGFloat {
    width / 2 * edgePushDeadZoneFraction
  }

  /// The next anchor for the given follow mode.
  ///
  /// - `cursorCentered`: always the cursor (ignores `previous`).
  /// - `edgePush`: keeps `previous` while the cursor stays within the dead zone;
  ///   otherwise trails the cursor so it sits exactly on the dead-zone boundary.
  ///   The result is clamped into `[0, viewSize]` so the scaled image always
  ///   covers the display (no black gutters at the edges).
  static func anchor(
    mode: Mode,
    cursor: CGPoint,
    previous: CGPoint,
    viewSize: CGSize
  ) -> CGPoint {
    switch mode {
    case .cursorCentered:
      return cursor
    case .edgePush:
      let dzx = edgePushDeadZone(width: viewSize.width)
      let dzy = edgePushDeadZone(width: viewSize.height)
      let x = pushed(cursor: cursor.x, anchor: previous.x, deadZone: dzx, limit: viewSize.width)
      let y = pushed(cursor: cursor.y, anchor: previous.y, deadZone: dzy, limit: viewSize.height)
      return CGPoint(x: x, y: y)
    }
  }

  /// One axis of edge-push: hold `anchor` while `cursor` is within `deadZone`,
  /// else trail it by exactly `deadZone`, then clamp into `[0, limit]`.
  private static func pushed(
    cursor: CGFloat,
    anchor: CGFloat,
    deadZone: CGFloat,
    limit: CGFloat
  ) -> CGFloat {
    var next = anchor
    if cursor > anchor + deadZone {
      next = cursor - deadZone
    } else if cursor < anchor - deadZone {
      next = cursor + deadZone
    }
    return min(max(next, 0), limit)
  }
}
