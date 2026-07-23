import Cocoa

/// Copies/saves a rendered snapshot (M3.5). Pure over its inputs — the
/// pasteboard and target directory are passed in — so the pasteboard and
/// file-write paths are unit-tested without touching the real clipboard or
/// `~/Pictures`. `OverlayWindow` renders the visible region and hands it here.
enum SnapshotExporter {
  enum ExportError: Error {
    /// The image couldn't be encoded to PNG.
    case encodingFailed
  }

  /// PNG-encodes an image (via its bitmap representation).
  static func pngData(from image: NSImage) -> Data? {
    guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff)
    else { return nil }
    return rep.representation(using: .png, properties: [:])
  }

  /// Replaces the pasteboard's contents with `image` (⌘C).
  static func copy(_ image: NSImage, to pasteboard: NSPasteboard) {
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
  }

  /// Writes `image` as a PNG into `directory` (creating it if needed), returning
  /// the file URL (⌘S). Default directory is `~/Pictures/XPlain`.
  @discardableResult
  static func savePNG(_ image: NSImage, to directory: URL, filename: String) throws -> URL {
    guard let data = pngData(from: image) else { throw ExportError.encodingFailed }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent(filename)
    try data.write(to: url)
    return url
  }

  /// The default save location, `~/Pictures/XPlain` (spec §3).
  static var defaultSaveDirectory: URL {
    let pictures =
      FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
      ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
    return pictures.appendingPathComponent("XPlain")
  }

  /// A timestamped PNG filename, e.g. `XPlain 2026-07-23 at 14.30.05.png`.
  static func timestampedFilename(date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
    return "XPlain \(formatter.string(from: date)).png"
  }
}
