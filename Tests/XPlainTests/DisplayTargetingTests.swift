import Cocoa
import XCTest

@testable import XPlain

final class DisplayTargetingTests: XCTestCase {
  func testCursorOnSingleScreenReturnsItsFrame() {
    let main = NSRect(x: 0, y: 0, width: 1440, height: 900)

    let result = DisplayTargeting.frame(
      at: NSPoint(x: 700, y: 400),
      in: [main],
      fallback: nil
    )

    XCTAssertEqual(result, main)
  }

  func testCursorOnSecondaryScreenWithNegativeOriginReturnsItsFrame() {
    // A common real layout: a secondary display to the left of main, so its
    // frame has a negative x origin.
    let main = NSRect(x: 0, y: 0, width: 1440, height: 900)
    let secondary = NSRect(x: -1920, y: 0, width: 1920, height: 1080)

    let onSecondary = DisplayTargeting.frame(
      at: NSPoint(x: -960, y: 540),
      in: [main, secondary],
      fallback: nil
    )
    XCTAssertEqual(onSecondary, secondary)

    let onMain = DisplayTargeting.frame(
      at: NSPoint(x: 200, y: 200),
      in: [main, secondary],
      fallback: nil
    )
    XCTAssertEqual(onMain, main)
  }

  func testCursorOutsideAllFramesFallsBackToProvidedFallback() {
    let main = NSRect(x: 0, y: 0, width: 1440, height: 900)
    let fallback = NSRect(x: 0, y: 0, width: 2560, height: 1440)

    let result = DisplayTargeting.frame(
      at: NSPoint(x: 9000, y: 9000),
      in: [main],
      fallback: fallback
    )

    XCTAssertEqual(result, fallback)
  }

  func testCursorOutsideAllFramesWithNoFallbackUsesFirstFrame() {
    let first = NSRect(x: 0, y: 0, width: 1440, height: 900)
    let second = NSRect(x: 1440, y: 0, width: 1920, height: 1080)

    let result = DisplayTargeting.frame(
      at: NSPoint(x: 9000, y: 9000),
      in: [first, second],
      fallback: nil
    )

    XCTAssertEqual(result, first)
  }

  func testNoScreensReturnsNil() {
    let result = DisplayTargeting.frame(
      at: NSPoint(x: 0, y: 0),
      in: [],
      fallback: nil
    )

    XCTAssertNil(result)
  }
}
