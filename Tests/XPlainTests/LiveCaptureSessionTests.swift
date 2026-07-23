import CoreGraphics
import XCTest

@testable import XPlain

@MainActor
final class LiveCaptureSessionTests: XCTestCase {
  // Integration test (docs/testing.md M5.1 row): with Screen Recording
  // permission, a live SCStream delivers a sequence of frames for a display.
  // Skips (never fails) without permission, like the M2.1 capture tests.
  func testLiveStreamDeliversASequenceOfFrames() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    let framesArrived = expectation(description: "several frames arrive")
    var count = 0
    let session = LiveCaptureSession { image in
      // Delivered on the main queue, so this closure runs on the main actor.
      MainActor.assumeIsolated {
        XCTAssertGreaterThan(image.width, 0)
        count += 1
        if count == 3 { framesArrived.fulfill() }
      }
    }

    try await session.start(of: CGMainDisplayID(), pixelSize: CGSize(width: 640, height: 480))
    await fulfillment(of: [framesArrived], timeout: 5)
    await session.stop()

    XCTAssertGreaterThanOrEqual(count, 3)
  }

  func testStartThrowsForUnknownDisplay() async throws {
    try XCTSkipUnless(
      CGPreflightScreenCaptureAccess(),
      "Screen Recording permission not granted in this environment"
    )

    let session = LiveCaptureSession { _ in }
    do {
      try await session.start(of: 0, pixelSize: CGSize(width: 640, height: 480))
      XCTFail("Expected CaptureService.CaptureError.noMatchingDisplay")
    } catch CaptureService.CaptureError.noMatchingDisplay {
      // Expected.
    }
    await session.stop()
  }
}
