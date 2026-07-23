import XCTest

@testable import XPlain

final class InputRouterTests: XCTestCase {
  // MARK: penCommand (M4.4)

  func testColorKeysMapToTheirColors() {
    XCTAssertEqual(InputRouter.penCommand(forKey: "r"), .setColor(.red))
    XCTAssertEqual(InputRouter.penCommand(forKey: "g"), .setColor(.green))
    XCTAssertEqual(InputRouter.penCommand(forKey: "b"), .setColor(.blue))
    XCTAssertEqual(InputRouter.penCommand(forKey: "o"), .setColor(.orange))
    XCTAssertEqual(InputRouter.penCommand(forKey: "y"), .setColor(.yellow))
    XCTAssertEqual(InputRouter.penCommand(forKey: "p"), .setColor(.pink))
  }

  func testHighlighterAndWidthKeys() {
    XCTAssertEqual(InputRouter.penCommand(forKey: "h"), .toggleHighlighter)
    XCTAssertEqual(InputRouter.penCommand(forKey: "]"), .widen)
    XCTAssertEqual(InputRouter.penCommand(forKey: "["), .narrow)
  }

  func testUnmappedKeyReturnsNil() {
    XCTAssertNil(InputRouter.penCommand(forKey: "q"))
    XCTAssertNil(InputRouter.penCommand(forKey: "1"))
  }

  // MARK: the full spec §4 key/modifier table (M4.10)

  func testColorKeysMapToPenColorCommands() {
    let expected: [String: PenColor] = [
      "r": .red, "g": .green, "b": .blue, "o": .orange, "y": .yellow, "p": .pink,
    ]
    for (key, color) in expected {
      XCTAssertEqual(InputRouter.command(key, command: false, shift: false), .pen(.setColor(color)))
    }
  }

  func testHighlighterAndWidthMapToPenCommands() {
    XCTAssertEqual(InputRouter.command("h", command: false, shift: false), .pen(.toggleHighlighter))
    XCTAssertEqual(InputRouter.command("]", command: false, shift: false), .pen(.widen))
    XCTAssertEqual(InputRouter.command("[", command: false, shift: false), .pen(.narrow))
  }

  func testToolAndBoardKeys() {
    XCTAssertEqual(InputRouter.command("t", command: false, shift: false), .beginText)
    XCTAssertEqual(InputRouter.command("w", command: false, shift: false), .whiteboard)
    XCTAssertEqual(InputRouter.command("k", command: false, shift: false), .blackboard)
    XCTAssertEqual(InputRouter.command("e", command: false, shift: false), .clear)
  }

  func testUndoRedoWithCommandAndShift() {
    XCTAssertEqual(InputRouter.command("z", command: true, shift: false), .undo)
    XCTAssertEqual(InputRouter.command("z", command: true, shift: true), .redo)
    // Shift uppercases the character; the router must still recognize it.
    XCTAssertEqual(InputRouter.command("Z", command: true, shift: true), .redo)
  }

  func testCommandCOrSAreNotOurCommands() {
    // ⌘C / ⌘S are the copy/save export, handled at the window — not draw commands.
    XCTAssertNil(InputRouter.command("c", command: true, shift: false))
    XCTAssertNil(InputRouter.command("s", command: true, shift: false))
  }

  func testUnmappedKeysReturnNil() {
    XCTAssertNil(InputRouter.command("q", command: false, shift: false))
    XCTAssertNil(InputRouter.command("5", command: false, shift: false))
    XCTAssertNil(InputRouter.command("t", command: true, shift: false))  // ⌘T isn't a command
  }
}
