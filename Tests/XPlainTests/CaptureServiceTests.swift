import Cocoa
import CoreGraphics
import XCTest

@testable import XPlain

final class CaptureServiceTests: XCTestCase {
  // Integration test (docs/testing.md M2.1 row): with Screen Recording
  // permission, snapshot(of:pixelSize:) returns a non-empty image at the
  // requested pixel size. CI (and this dev machine, per docs/loop-guide.md)
  // has no Screen Recording permission, so this skips rather than fails when
  // it's absent — never block the gates on a resource that isn't there.
  func testSnapshotReturnsNonEmptyImageAtDisplayPixelSize() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    let displayID = CGMainDisplayID()
    let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1440, height: 900)
    let image = try await CaptureService.snapshot(of: displayID, pixelSize: screenSize)

    XCTAssertGreaterThan(image.width, 0)
    XCTAssertGreaterThan(image.height, 0)
  }

  // M2.4 regression test: on a Retina display, requesting the display's raw
  // point size (rather than point-size x backingScaleFactor) would silently
  // return a sub-native-resolution image — visibly blurry once rendered 1:1
  // into the overlay. Assert the returned image honors whatever pixel size is
  // requested, so callers (see OverlayController.showCapturedSnapshot) are
  // responsible for passing the true native pixel size.
  func testSnapshotHonorsTheRequestedPixelSize() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    let displayID = CGMainDisplayID()
    let requestedSize = CGSize(width: 640, height: 480)
    let image = try await CaptureService.snapshot(of: displayID, pixelSize: requestedSize)

    XCTAssertEqual(image.width, 640)
    XCTAssertEqual(image.height, 480)
  }

  func testSnapshotThrowsForUnknownDisplay() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    // 0 is never a real CGDirectDisplayID (main display is always non-zero).
    do {
      _ = try await CaptureService.snapshot(of: 0, pixelSize: CGSize(width: 640, height: 480))
      XCTFail("Expected CaptureService.CaptureError.noMatchingDisplay")
    } catch CaptureService.CaptureError.noMatchingDisplay {
      // Expected.
    }
  }
}
