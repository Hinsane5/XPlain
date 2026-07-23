import CoreGraphics
import XCTest

@testable import XPlain

/// Pure Y-flip math (M2.3) — unlike `CaptureServiceTests`, these never touch
/// real capture/permission, so they always run (never skip).
final class CaptureServiceYFlipTests: XCTestCase {
  private let displayHeights: [CGFloat] = [900, 1080, 1440]

  func testAppKitBottomMapsToCGImageTop() {
    // AppKit's origin (bottom-left) is the top row in CGImage's (top-left)
    // space, i.e. y = displayHeight.
    for height in displayHeights {
      let flipped = CaptureService.flipY(CGPoint(x: 100, y: 0), displayHeight: height)
      XCTAssertEqual(flipped, CGPoint(x: 100, y: height))
    }
  }

  func testAppKitTopMapsToCGImageOrigin() {
    for height in displayHeights {
      let flipped = CaptureService.flipY(CGPoint(x: 100, y: height), displayHeight: height)
      XCTAssertEqual(flipped, CGPoint(x: 100, y: 0))
    }
  }

  func testFlippingAPointTwiceReturnsTheOriginal() {
    let points = [
      CGPoint(x: 0, y: 0),
      CGPoint(x: 250, y: 333),
      CGPoint(x: 1920, y: 1080),
    ]
    for height in displayHeights {
      for point in points {
        let roundTripped = CaptureService.flipY(
          CaptureService.flipY(point, displayHeight: height),
          displayHeight: height
        )
        XCTAssertEqual(roundTripped, point)
      }
    }
  }

  func testRectAtAppKitTopMapsToCGImageTop() {
    // A rect sitting at the very top in AppKit's bottom-left space (its origin
    // is displayHeight - rect.height from the bottom) must land at y = 0 in
    // CGImage's top-left space — the top row.
    for height in displayHeights {
      let rect = CGRect(x: 0, y: height - 50, width: 200, height: 50)
      let flipped = CaptureService.flipY(rect, displayHeight: height)
      XCTAssertEqual(flipped, CGRect(x: 0, y: 0, width: 200, height: 50))
    }
  }

  func testRectAtAppKitBottomMapsToCGImageBottom() {
    for height in displayHeights {
      let rect = CGRect(x: 0, y: 0, width: 200, height: 50)
      let flipped = CaptureService.flipY(rect, displayHeight: height)
      XCTAssertEqual(flipped, CGRect(x: 0, y: height - 50, width: 200, height: 50))
    }
  }

  func testFlippingARectTwiceReturnsTheOriginal() {
    let rects = [
      CGRect(x: 0, y: 0, width: 100, height: 100),
      CGRect(x: 300, y: 400, width: 640, height: 480),
    ]
    for height in displayHeights {
      for rect in rects {
        let roundTripped = CaptureService.flipY(
          CaptureService.flipY(rect, displayHeight: height),
          displayHeight: height
        )
        XCTAssertEqual(roundTripped, rect)
      }
    }
  }
}
