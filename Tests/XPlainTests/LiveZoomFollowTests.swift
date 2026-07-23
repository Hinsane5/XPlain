import XCTest

@testable import XPlain

/// M5.4: the pure cursor-follow math for LiveZoom. Both modes pick the *anchor*
/// — the display point the magnifier is scaled about (`ZoomRenderer.transform`)
/// — from the live cursor. Cursor-centered tracks the cursor every frame;
/// edge-push holds the view still until the cursor nears the edge, then scrolls.
final class LiveZoomFollowTests: XCTestCase {
  private let viewSize = CGSize(width: 1000, height: 800)

  func testCursorCenteredAnchorAlwaysEqualsCursor() {
    // Cursor-centered: the anchor is the cursor every frame (the previous anchor
    // is ignored), so the real cursor always points at true magnified content.
    let cursor = CGPoint(x: 620, y: 410)
    let anchor = LiveZoomFollow.anchor(
      mode: .cursorCentered,
      cursor: cursor,
      previous: CGPoint(x: 100, y: 100),
      viewSize: viewSize
    )
    XCTAssertEqual(anchor, cursor)
  }

  func testEdgePushHoldsStillWhileCursorRoamsTheDeadZone() {
    // Edge-push: while the cursor stays within the dead zone of the current
    // anchor, the anchor doesn't move — the magnified view is stable.
    let previous = CGPoint(x: 500, y: 400)
    let anchor = LiveZoomFollow.anchor(
      mode: .edgePush,
      cursor: CGPoint(x: 560, y: 440),  // small move, inside the dead zone
      previous: previous,
      viewSize: viewSize
    )
    XCTAssertEqual(anchor, previous)
  }

  func testEdgePushScrollsWhenCursorLeavesTheDeadZone() {
    // Once the cursor moves past the dead zone, the anchor trails it, staying
    // exactly one dead-zone away so the cursor sits at the dead-zone boundary.
    let previous = CGPoint(x: 500, y: 400)
    let dzx = LiveZoomFollow.edgePushDeadZone(width: viewSize.width)
    let cursor = CGPoint(x: 900, y: 400)  // far right, well past the dead zone
    let anchor = LiveZoomFollow.anchor(
      mode: .edgePush,
      cursor: cursor,
      previous: previous,
      viewSize: viewSize
    )
    XCTAssertEqual(anchor.x, cursor.x - dzx, accuracy: 0.001)
    XCTAssertEqual(anchor.y, previous.y, accuracy: 0.001)  // no vertical move
  }

  func testEdgePushClampsAnchorIntoTheDisplay() {
    // The anchor never leaves the display, so the scaled image always covers the
    // screen (no black gutters). A stale/out-of-range previous is clamped back in.
    let anchor = LiveZoomFollow.anchor(
      mode: .edgePush,
      cursor: CGPoint(x: 1200, y: 900),  // off the display
      previous: CGPoint(x: 1200, y: 900),
      viewSize: viewSize
    )
    XCTAssertEqual(anchor.x, viewSize.width, accuracy: 0.001)
    XCTAssertEqual(anchor.y, viewSize.height, accuracy: 0.001)
  }
}
