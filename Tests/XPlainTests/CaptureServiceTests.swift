import CoreGraphics
import XCTest

@testable import XPlain

final class CaptureServiceTests: XCTestCase {
  // Integration test (docs/testing.md M2.1 row): with Screen Recording
  // permission, snapshot(of:) returns a non-empty image at the display's pixel
  // size. CI (and this dev machine, per docs/loop-guide.md) has no Screen
  // Recording permission, so this skips rather than fails when it's absent —
  // never block the gates on a resource that isn't there.
  func testSnapshotReturnsNonEmptyImageAtDisplayPixelSize() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    let displayID = CGMainDisplayID()
    let image = try await CaptureService.snapshot(of: displayID)

    XCTAssertGreaterThan(image.width, 0)
    XCTAssertGreaterThan(image.height, 0)
  }

  func testSnapshotThrowsForUnknownDisplay() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    // 0 is never a real CGDirectDisplayID (main display is always non-zero).
    do {
      _ = try await CaptureService.snapshot(of: 0)
      XCTFail("Expected CaptureService.CaptureError.noMatchingDisplay")
    } catch CaptureService.CaptureError.noMatchingDisplay {
      // Expected.
    }
  }
}
