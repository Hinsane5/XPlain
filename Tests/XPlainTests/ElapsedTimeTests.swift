import XCTest

@testable import XPlain

/// M5.9: the pure elapsed-time formatting for the recording HUD. The visible
/// menu-bar indicator is checked in specs/m5-manual-checklist.md.
final class ElapsedTimeTests: XCTestCase {
  func testFormatsUnderAMinuteAsMinuteColonSeconds() {
    XCTAssertEqual(ElapsedTime.format(0), "0:00")
    XCTAssertEqual(ElapsedTime.format(7), "0:07")
    XCTAssertEqual(ElapsedTime.format(59), "0:59")
  }

  func testFormatsMinutesAndSeconds() {
    XCTAssertEqual(ElapsedTime.format(60), "1:00")
    XCTAssertEqual(ElapsedTime.format(65), "1:05")
    XCTAssertEqual(ElapsedTime.format(754), "12:34")
  }

  func testFormatsHoursWithZeroPaddedMinutes() {
    XCTAssertEqual(ElapsedTime.format(3600), "1:00:00")
    XCTAssertEqual(ElapsedTime.format(3661), "1:01:01")
    XCTAssertEqual(ElapsedTime.format(37_262), "10:21:02")
  }

  func testTruncatesFractionalSeconds() {
    XCTAssertEqual(ElapsedTime.format(7.9), "0:07")
    XCTAssertEqual(ElapsedTime.format(59.99), "0:59")
  }
}
