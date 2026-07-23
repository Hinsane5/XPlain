import XCTest

@testable import XPlain

final class InputRouterTests: XCTestCase {
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
}
