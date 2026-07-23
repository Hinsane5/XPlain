import Cocoa
import XCTest

@testable import XPlain

final class SnapshotExporterTests: XCTestCase {
  private func makeImage(width: Int, height: Int) -> NSImage {
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(NSColor.red.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let cgImage = context.makeImage()!
    return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
  }

  func testPNGDataHasThePNGSignature() throws {
    let data = try XCTUnwrap(SnapshotExporter.pngData(from: makeImage(width: 20, height: 10)))
    // PNG magic: 0x89 'P' 'N' 'G'.
    XCTAssertEqual(Array(data.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
  }

  func testCopyPutsAnImageOnTheGivenPasteboard() {
    // A uniquely-named pasteboard, so the test never touches the real clipboard.
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("XPlainTest-\(UUID().uuidString)"))
    SnapshotExporter.copy(makeImage(width: 8, height: 8), to: pasteboard)

    let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)
    XCTAssertEqual(images?.count, 1)
    pasteboard.releaseGlobally()
  }

  func testSavePNGWritesAReadableFileOfTheExpectedSize() throws {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("XPlainTest-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: dir) }

    let url = try SnapshotExporter.savePNG(
      makeImage(width: 40, height: 30),
      to: dir,
      filename: "shot.png"
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    let written = try XCTUnwrap(NSImage(contentsOf: url))
    let rep = try XCTUnwrap(written.representations.first)
    XCTAssertEqual(rep.pixelsWide, 40)
    XCTAssertEqual(rep.pixelsHigh, 30)
  }
}
