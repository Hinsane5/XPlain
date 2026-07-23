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

  func testShowPermissionPromptInstallsMessageAndDeepLinkButton() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))

    window.showPermissionPrompt()

    let label = window.contentView?.subviews.compactMap { $0 as? NSTextField }.first
    XCTAssertEqual(label?.stringValue, PermissionPromptContent.message)

    let button = window.contentView?.subviews.compactMap { $0 as? NSButton }.first
    XCTAssertEqual(button?.title, PermissionPromptContent.buttonTitle)
  }

  func testRightClickOnPermissionButtonStillDismisses() {
    // Regression: NSButton's default swallows rightMouseDown, so a right-click
    // landing on the prompt's button never reached the window — it took a second
    // click outside the button to dismiss. The button must forward right-clicks.
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    var dismissed = false
    window.onDismissRequested = { dismissed = true }
    window.showPermissionPrompt()

    let button = window.contentView?.subviews.compactMap { $0 as? NSButton }.first
    button?.rightMouseDown(with: Self.mouseEvent())

    XCTAssertTrue(dismissed)
  }

  func testShowImageInstallsAnImageViewWithTheGivenImage() {
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    let image = Self.makeTestImage(width: 100, height: 50)

    window.showImage(image)

    // The image view lives inside the clipping container (M3.1), so search the
    // hierarchy rather than assuming contentView is the image view itself.
    let imageView = window.contentView?.subviews.compactMap { $0 as? NSImageView }.first
    XCTAssertNotNil(imageView)
    XCTAssertEqual(imageView?.image?.size, window.frame.size)

    var proposedRect = NSRect(origin: .zero, size: imageView?.image?.size ?? .zero)
    let resolved = imageView?.image?.cgImage(
      forProposedRect: &proposedRect,
      context: nil,
      hints: nil
    )
    XCTAssertEqual(resolved?.width, 100)
    XCTAssertEqual(resolved?.height, 50)
  }

  func testShowImageAtOneXFillsTheWindow() {
    // 1× (no magnification) → the image view fills the window exactly, matching
    // the M2.4 render.
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    window.showImage(Self.makeTestImage(width: 100, height: 50), magnifiedBy: 1, about: .zero)

    let imageView = window.contentView?.subviews.compactMap { $0 as? NSImageView }.first
    XCTAssertEqual(imageView?.frame, NSRect(x: 0, y: 0, width: 800, height: 600))
  }

  func testShowImageMagnifiedGrowsAndReanchorsOnTheCursor() {
    // 2× about the window center → image view is 2× the window and re-anchored
    // so the center stays fixed (origin = center · (1 − scale)).
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    window.showImage(
      Self.makeTestImage(width: 100, height: 50),
      magnifiedBy: 2,
      about: CGPoint(x: 400, y: 300)
    )

    let imageView = window.contentView?.subviews.compactMap { $0 as? NSImageView }.first
    XCTAssertEqual(imageView?.frame, NSRect(x: -400, y: -300, width: 1600, height: 1200))
  }

  func testMouseMoveRepansTheMagnifiedImageOnTheNewCursor() {
    // M3.2: while zoomed, moving the mouse re-anchors the magnified image on the
    // new cursor position (pan), so the content under the pointer tracks it 1:1.
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    window.showImage(
      Self.makeTestImage(width: 100, height: 50),
      magnifiedBy: 2,
      about: CGPoint(x: 400, y: 300)
    )

    window.mouseMoved(with: Self.mouseMovedEvent(at: CGPoint(x: 200, y: 150)))

    let imageView = window.contentView?.subviews.compactMap { $0 as? NSImageView }.first
    // Re-anchored on (200,150): origin = point · (1 − scale) = (−200, −150).
    XCTAssertEqual(imageView?.frame, NSRect(x: -200, y: -150, width: 1600, height: 1200))
  }

  func testMouseMoveDoesNothingAtOneX() {
    // At 1× there's nothing to pan; a mouse move must not move the image view.
    let window = OverlayWindow(displayFrame: NSRect(x: 0, y: 0, width: 800, height: 600))
    window.showImage(Self.makeTestImage(width: 100, height: 50), magnifiedBy: 1, about: .zero)

    window.mouseMoved(with: Self.mouseMovedEvent(at: CGPoint(x: 200, y: 150)))

    let imageView = window.contentView?.subviews.compactMap { $0 as? NSImageView }.first
    XCTAssertEqual(imageView?.frame, NSRect(x: 0, y: 0, width: 800, height: 600))
  }

  private static func mouseMovedEvent(at point: CGPoint) -> NSEvent {
    NSEvent.mouseEvent(
      with: .mouseMoved,
      location: point,
      modifierFlags: [],
      timestamp: 0,
      windowNumber: 0,
      context: nil,
      eventNumber: 0,
      clickCount: 0,
      pressure: 0
    )!
  }

  private static func makeTestImage(width: Int, height: Int) -> CGImage {
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context.makeImage()!
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
