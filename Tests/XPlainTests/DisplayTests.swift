import Cocoa
import XCTest

@testable import XPlain

final class DisplayTests: XCTestCase {
  func testCursorOnSingleDisplayReturnsIt() {
    let main = Display(
      frame: NSRect(x: 0, y: 0, width: 1440, height: 900),
      displayID: 1,
      backingScaleFactor: 2
    )

    let result = DisplayTargeting.display(
      at: NSPoint(x: 700, y: 400),
      in: [main],
      fallback: nil
    )

    XCTAssertEqual(result, main)
  }

  func testCursorOnSecondaryDisplayWithNegativeOriginReturnsIt() {
    let main = Display(
      frame: NSRect(x: 0, y: 0, width: 1440, height: 900),
      displayID: 1,
      backingScaleFactor: 2
    )
    let secondary = Display(
      frame: NSRect(x: -1920, y: 0, width: 1920, height: 1080),
      displayID: 2,
      backingScaleFactor: 1
    )

    let onSecondary = DisplayTargeting.display(
      at: NSPoint(x: -960, y: 540),
      in: [main, secondary],
      fallback: nil
    )
    XCTAssertEqual(onSecondary, secondary)

    let onMain = DisplayTargeting.display(
      at: NSPoint(x: 200, y: 200),
      in: [main, secondary],
      fallback: nil
    )
    XCTAssertEqual(onMain, main)
  }

  func testCursorOutsideAllDisplaysFallsBackToProvidedFallback() {
    let main = Display(
      frame: NSRect(x: 0, y: 0, width: 1440, height: 900),
      displayID: 1,
      backingScaleFactor: 2
    )
    let fallback = Display(
      frame: NSRect(x: 0, y: 0, width: 2560, height: 1440),
      displayID: 9,
      backingScaleFactor: 1
    )

    let result = DisplayTargeting.display(
      at: NSPoint(x: 9000, y: 9000),
      in: [main],
      fallback: fallback
    )

    XCTAssertEqual(result, fallback)
  }

  func testNoDisplaysReturnsNil() {
    let result = DisplayTargeting.display(
      at: NSPoint(x: 0, y: 0),
      in: [],
      fallback: nil
    )

    XCTAssertNil(result)
  }

  func testPixelSizeMultipliesFrameByBackingScaleFactor() {
    let display = Display(
      frame: NSRect(x: 0, y: 0, width: 1470, height: 956),
      displayID: 1,
      backingScaleFactor: 2
    )

    XCTAssertEqual(display.pixelSize, CGSize(width: 2940, height: 1912))
  }
}
