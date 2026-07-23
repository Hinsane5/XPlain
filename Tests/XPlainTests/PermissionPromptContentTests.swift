import XCTest

@testable import XPlain

final class PermissionPromptContentTests: XCTestCase {
  func testMessageAndButtonTitleAreNonEmpty() {
    XCTAssertFalse(PermissionPromptContent.message.isEmpty)
    XCTAssertFalse(PermissionPromptContent.buttonTitle.isEmpty)
  }

  func testSystemSettingsURLTargetsTheScreenRecordingPane() {
    // The documented deep link into System Settings' Screen Recording pane
    // (docs/security.md) — must stay exact or the button opens the wrong pane.
    XCTAssertEqual(
      PermissionPromptContent.systemSettingsURL.absoluteString,
      "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )
  }
}
