import AppKit
import XCTest

@testable import XPlain

/// M6.3: detecting when a chosen shortcut collides with a well-known macOS system
/// shortcut, so the Settings hotkey recorder can warn about it.
final class HotkeyConflictTests: XCTestCase {
  // Carbon/virtual key codes (same as NSEvent.keyCode).
  private let key1 = 18
  private let key4 = 21
  private let keyZ = 6
  private let keySpace = 49

  func testControlDigitsCollideWithMissionControlSpaces() {
    // ⌃1–⌃4 switch Spaces — the exact collision docs/CLAUDE.md tells us to avoid.
    XCTAssertNotNil(HotkeyConflict.name(carbonKeyCode: key1, modifiers: [.control]))
    XCTAssertNotNil(HotkeyConflict.name(carbonKeyCode: key4, modifiers: [.control]))
  }

  func testCommandSpaceCollidesWithSpotlight() {
    XCTAssertEqual(
      HotkeyConflict.name(carbonKeyCode: keySpace, modifiers: [.command]),
      "Spotlight"
    )
  }

  func testExtraModifierAvoidsTheConflict() {
    // ⌘⌃1 is a different chord than ⌃1 — not a Spaces conflict.
    XCTAssertNil(HotkeyConflict.name(carbonKeyCode: key1, modifiers: [.command, .control]))
  }

  func testDefaultXPlainChordIsClear() {
    // ⌘⌃Z (the Zoom default) collides with nothing known.
    XCTAssertNil(HotkeyConflict.name(carbonKeyCode: keyZ, modifiers: [.command, .control]))
  }

  func testIgnoresIrrelevantModifierBits() {
    // Caps-lock / function bits riding along don't hide a real conflict.
    XCTAssertNotNil(
      HotkeyConflict.name(carbonKeyCode: key1, modifiers: [.control, .capsLock])
    )
  }
}
