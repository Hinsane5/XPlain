import XCTest

@testable import XPlain

final class ModeActivationGateTests: XCTestCase {
  func testGrantedPermissionResolvesToTheRequestedMode() {
    for mode: Mode in [.zoom, .draw, .liveZoom, .record] {
      XCTAssertEqual(
        ModeActivationGate.resolve(requested: mode, permissionGranted: true),
        mode
      )
    }
  }

  func testDeniedPermissionResolvesToPermissionPrompt() {
    for mode: Mode in [.zoom, .draw, .liveZoom, .record] {
      XCTAssertEqual(
        ModeActivationGate.resolve(requested: mode, permissionGranted: false),
        .permissionPrompt
      )
    }
  }

  func testIdleNeverNeedsPermission() {
    XCTAssertEqual(ModeActivationGate.resolve(requested: .idle, permissionGranted: false), .idle)
    XCTAssertEqual(ModeActivationGate.resolve(requested: .idle, permissionGranted: true), .idle)
  }
}
