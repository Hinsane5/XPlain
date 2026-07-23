import XCTest

@testable import XPlain

final class ModeControllerTests: XCTestCase {
  func testIdleZoomDrawIdleSequence() {
    let controller = ModeController()
    XCTAssertEqual(controller.current, .idle)
    XCTAssertFalse(controller.isActive)

    XCTAssertTrue(controller.request(.zoom))
    XCTAssertEqual(controller.current, .zoom)
    XCTAssertTrue(controller.isActive)

    XCTAssertTrue(controller.request(.draw))
    XCTAssertEqual(controller.current, .draw)

    XCTAssertTrue(controller.exit())
    XCTAssertEqual(controller.current, .idle)
    XCTAssertFalse(controller.isActive)
  }

  func testSingleActiveModeSwitchingReplacesPrevious() {
    let controller = ModeController()
    controller.request(.zoom)
    XCTAssertEqual(controller.current, .zoom)

    controller.request(.draw)  // Zoom → Draw replaces, never stacks.
    XCTAssertEqual(controller.current, .draw)
  }

  func testIllegalTransitionsRejected() {
    let controller = ModeController()
    controller.request(.liveZoom)

    // From LiveZoom you must exit to idle first; a direct switch is rejected.
    XCTAssertFalse(controller.request(.zoom))
    XCTAssertEqual(controller.current, .liveZoom)

    // Re-entering the current mode is a no-op.
    XCTAssertFalse(controller.request(.liveZoom))
    XCTAssertEqual(controller.current, .liveZoom)
  }

  func testPermissionPromptIsReachableFromIdleAndExitsToIdle() {
    let controller = ModeController()
    XCTAssertTrue(controller.request(.permissionPrompt))
    XCTAssertEqual(controller.current, .permissionPrompt)

    XCTAssertTrue(controller.exit())
    XCTAssertEqual(controller.current, .idle)
  }

  func testPermissionPromptCannotSwitchDirectlyToAnotherMode() {
    let controller = ModeController()
    controller.request(.permissionPrompt)

    // Must exit to idle first, same as every other mode.
    XCTAssertFalse(controller.request(.zoom))
    XCTAssertEqual(controller.current, .permissionPrompt)
  }

  func testOnChangeReportsFromAndTo() {
    let controller = ModeController()
    var changes: [String] = []
    controller.onChange = { from, next in changes.append("\(from)->\(next)") }

    controller.request(.zoom)
    controller.request(.draw)
    controller.exit()

    XCTAssertEqual(changes, ["idle->zoom", "zoom->draw", "draw->idle"])
  }
}
