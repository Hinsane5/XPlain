import CoreGraphics
import XCTest

@testable import XPlain

final class ZoomRendererTests: XCTestCase {
  func testDefaultScaleIsTwo() {
    XCTAssertEqual(ZoomRenderer.defaultScale, 2)
  }

  func testCursorIsAFixedPointOfTheZoomTransform() {
    // Zooming "about" the cursor means the point under the cursor stays put —
    // the content there doesn't slide out from under the pointer.
    let cursor = CGPoint(x: 300, y: 200)
    let transformed = cursor.applying(ZoomRenderer.transform(scale: 2, about: cursor))
    XCTAssertEqual(transformed.x, cursor.x, accuracy: 0.0001)
    XCTAssertEqual(transformed.y, cursor.y, accuracy: 0.0001)
  }

  func testPointOffsetFromCursorMovesOutByTheScaleFactor() {
    let cursor = CGPoint(x: 100, y: 100)
    let transform = ZoomRenderer.transform(scale: 2, about: cursor)

    // 50pt right of the cursor → 100pt right (2×) after magnification.
    let right = CGPoint(x: 150, y: 100).applying(transform)
    XCTAssertEqual(right.x, 200, accuracy: 0.0001)
    XCTAssertEqual(right.y, 100, accuracy: 0.0001)

    // 30pt above → 60pt above.
    let above = CGPoint(x: 100, y: 130).applying(transform)
    XCTAssertEqual(above.x, 100, accuracy: 0.0001)
    XCTAssertEqual(above.y, 160, accuracy: 0.0001)
  }

  func testScaleOfOneIsTheIdentity() {
    let transform = ZoomRenderer.transform(scale: 1, about: CGPoint(x: 42, y: 99))
    XCTAssertEqual(transform, .identity)
  }

  func testPanIsLinearInCursorMovement() {
    // M3.2: as the cursor moves by Δ, the magnified image's origin shifts by
    // −Δ·(scale−1) — i.e. panning tracks the cursor 1:1 (the point under the
    // pointer stays under it). Verify the origin delta between two cursors.
    let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let scale: CGFloat = 3
    let before = display.applying(
      ZoomRenderer.transform(scale: scale, about: CGPoint(x: 100, y: 100))
    )
    let after = display.applying(
      ZoomRenderer.transform(scale: scale, about: CGPoint(x: 140, y: 90))
    )

    // Δcursor = (40, −10) → Δorigin = −Δ·(scale−1) = (−80, 20).
    XCTAssertEqual(after.origin.x - before.origin.x, -80, accuracy: 0.0001)
    XCTAssertEqual(after.origin.y - before.origin.y, 20, accuracy: 0.0001)
  }

  func testMagnifiedFrameForARectScalesAndReanchorsOnTheCursor() {
    // The overlay applies the transform to its full-display rect to place the
    // magnified image view. A 1000×800 display zoomed 2× about its center
    // becomes 2000×1600, re-anchored so the center point stays fixed.
    let display = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let center = CGPoint(x: 500, y: 400)
    let framed = display.applying(ZoomRenderer.transform(scale: 2, about: center))

    XCTAssertEqual(framed.width, 2000, accuracy: 0.0001)
    XCTAssertEqual(framed.height, 1600, accuracy: 0.0001)
    // origin = center * (1 - scale) = 500*(-1), 400*(-1)
    XCTAssertEqual(framed.origin.x, -500, accuracy: 0.0001)
    XCTAssertEqual(framed.origin.y, -400, accuracy: 0.0001)
  }
}
