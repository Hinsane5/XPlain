import KeyboardShortcuts
import XCTest

@testable import XPlain

final class HotkeyServiceTests: XCTestCase {
  func testEachShortcutEmitsItsDistinctMode() {
    var emitted: [Mode] = []
    let service = HotkeyService { emitted.append($0) }

    service.trigger(.zoom)
    service.trigger(.draw)
    service.trigger(.liveZoom)
    service.trigger(.record)

    XCTAssertEqual(emitted, [.zoom, .draw, .liveZoom, .record])
  }

  func testModeMappingIsCorrect() {
    let service = HotkeyService { _ in }

    XCTAssertEqual(service.mode(for: .zoom), .zoom)
    XCTAssertEqual(service.mode(for: .draw), .draw)
    XCTAssertEqual(service.mode(for: .liveZoom), .liveZoom)
    XCTAssertEqual(service.mode(for: .record), .record)
  }

  func testDefaultChordsUseCommandControlAndAvoidMissionControlSpaces() throws {
    // ⌃1–⌃4 collide with macOS Mission Control Space switching, so every default
    // chord must be ⌘⌃-based — assert Command and Control are both present.
    for name in [KeyboardShortcuts.Name.zoom, .draw, .liveZoom, .record] {
      let shortcut = try XCTUnwrap(name.defaultShortcut)
      XCTAssertTrue(shortcut.modifiers.contains(.command))
      XCTAssertTrue(shortcut.modifiers.contains(.control))
    }
  }
}
