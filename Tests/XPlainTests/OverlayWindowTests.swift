import Cocoa
import XCTest

@testable import XPlain

final class OverlayWindowTests: XCTestCase {
  func testWindowUsesGivenDisplayFrame() {
    let frame = NSRect(x: 100, y: 200, width: 1440, height: 900)
    let window = OverlayWindow(displayFrame: frame)
    XCTAssertEqual(window.frame, frame)
  }

  func testWindowIsBorderlessAndCanBecomeKey() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    XCTAssertTrue(window.styleMask.contains(.borderless))
    XCTAssertTrue(window.canBecomeKey)
  }

  func testFrameIsNotConstrainedOffMainScreen() {
    // A full-display overlay must never be repositioned by AppKit, even when the
    // frame sits on a secondary display far from the main one.
    let far = NSRect(x: 5000, y: -1200, width: 2560, height: 1440)
    let window = OverlayWindow(displayFrame: far)
    XCTAssertEqual(window.frame, far)
  }

  func testWindowLevelIsAboveMainMenu() {
    // Must sit above the menu bar so it's actually visible when shown, per M1.4.
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    XCTAssertGreaterThan(window.level, .mainMenu)
  }

  func testCollectionBehaviorCoversFullScreenAppsAndAllSpaces() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    let behavior = window.collectionBehavior
    XCTAssertTrue(behavior.contains(.canJoinAllSpaces))
    XCTAssertTrue(behavior.contains(.fullScreenAuxiliary))
    XCTAssertTrue(behavior.contains(.stationary))
  }

  func testEscKeyRequestsDismissal() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    var dismissed = false
    window.onDismissRequested = { dismissed = true }

    window.keyDown(with: Self.keyEvent(keyCode: 53))  // Esc

    XCTAssertTrue(dismissed)
  }

  func testNonEscKeyDoesNotRequestDismissal() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    var dismissed = false
    window.onDismissRequested = { dismissed = true }

    window.keyDown(with: Self.keyEvent(keyCode: 6))  // 'z', arbitrary non-Esc key

    XCTAssertFalse(dismissed)
  }

  func testRightClickRequestsDismissal() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    var dismissed = false
    window.onDismissRequested = { dismissed = true }

    window.rightMouseDown(with: Self.mouseEvent())

    XCTAssertTrue(dismissed)
  }

  private static func keyEvent(keyCode: UInt16) -> NSEvent {
    NSEvent.keyEvent(
      with: .keyDown,
      location: .zero,
      modifierFlags: [],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      characters: "",
      charactersIgnoringModifiers: "",
      isARepeat: false,
      keyCode: keyCode
    )!
  }

  private static func mouseEvent() -> NSEvent {
    NSEvent.mouseEvent(
      with: .rightMouseDown,
      location: .zero,
      modifierFlags: [],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      eventNumber: 0,
      clickCount: 1,
      pressure: 1
    )!
  }
}
