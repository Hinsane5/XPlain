import XCTest

@testable import XPlain

/// M5.6: the pure crop math turning a drag-selected rectangle into the
/// ScreenCaptureKit `sourceRect` (points, top-left origin) plus the output pixel
/// size for the writer. The drag UI and live cropped recording are checked in
/// specs/m5-manual-checklist.md.
final class RecordingRegionTests: XCTestCase {
  // A 1440×900-point display at 2× (so 2880×1800 native pixels).
  private let displaySize = CGSize(width: 1440, height: 900)
  private let scale: CGFloat = 2

  func testSourceRectFlipsSelectionToTopLeftOrigin() {
    // A selection whose bottom edge sits at the display bottom (y = 0, height
    // 300) becomes a top-left rect whose top edge is 300pt up from the bottom,
    // i.e. y = displayHeight - maxY = 900 - 300 = 600.
    let selection = CGRect(x: 100, y: 0, width: 400, height: 300)
    let source = RecordingRegion.sourceRect(
      selection: selection,
      displayHeightPoints: displaySize.height
    )
    XCTAssertEqual(source, CGRect(x: 100, y: 600, width: 400, height: 300))
  }

  func testPixelSizeIsSelectionScaledToNativeAndEven() {
    // Native pixels = selection points × backingScaleFactor; H.264 wants even
    // dimensions, so odd results round down to even.
    let selection = CGRect(x: 0, y: 0, width: 401, height: 300)  // 401 → 802 even
    let size = RecordingRegion.pixelSize(selection: selection, scale: scale)
    XCTAssertEqual(size, CGSize(width: 802, height: 600))
  }

  func testPixelSizeRoundsOddNativeDimensionsDownToEven() {
    let selection = CGRect(x: 0, y: 0, width: 100.5, height: 100.5)  // ×2 = 201 → 200
    let size = RecordingRegion.pixelSize(selection: selection, scale: 2)
    XCTAssertEqual(size, CGSize(width: 200, height: 200))
  }

  func testSelectionIsClampedIntoTheDisplay() {
    // A drag that runs off the display edges is clipped to the display bounds so
    // the captured region never exceeds what exists.
    let ragged = CGRect(x: -50, y: -50, width: 2000, height: 2000)
    let clamped = RecordingRegion.clamped(ragged, to: displaySize)
    XCTAssertEqual(clamped, CGRect(origin: .zero, size: displaySize))
  }

  func testTooSmallSelectionIsRejected() {
    // A stray click / tiny drag isn't a usable region — reject it so recording
    // falls back to full-screen rather than writing a 2px file.
    let tiny = CGRect(x: 10, y: 10, width: 3, height: 3)
    XCTAssertFalse(RecordingRegion.isUsable(tiny))
    XCTAssertTrue(RecordingRegion.isUsable(CGRect(x: 0, y: 0, width: 200, height: 150)))
  }
}
