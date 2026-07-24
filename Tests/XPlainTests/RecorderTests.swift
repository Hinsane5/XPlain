import AVFoundation
import XCTest

@testable import XPlain

/// M5.5: the Recorder's pure, hardware-free pieces — output location, filename,
/// and the H.264 writer settings. The live SCStream→AVAssetWriter path (start →
/// stop → playable file) needs real Screen Recording permission and is checked
/// in specs/m5-manual-checklist.md, not here.
final class RecorderTests: XCTestCase {
  func testDefaultSaveDirectoryIsMoviesXPlain() {
    // Spec §6: recordings land in ~/Movies/XPlain (folder configurable later).
    let dir = Recorder.defaultSaveDirectory
    XCTAssertEqual(dir.lastPathComponent, "XPlain")
    XCTAssertEqual(dir.deletingLastPathComponent().lastPathComponent, "Movies")
  }

  func testTimestampedFilenameIsAnMP4() {
    let name = Recorder.timestampedFilename(
      date: Date(timeIntervalSince1970: 0)
    )
    XCTAssertTrue(name.hasPrefix("XPlain "))
    XCTAssertTrue(name.hasSuffix(".mp4"))
  }

  func testVideoSettingsAreH264AtTheGivenPixelSize() {
    let settings = Recorder.videoSettings(width: 2880, height: 1800)
    XCTAssertEqual(settings[AVVideoCodecKey] as? AVVideoCodecType, .h264)
    XCTAssertEqual(settings[AVVideoWidthKey] as? Int, 2880)
    XCTAssertEqual(settings[AVVideoHeightKey] as? Int, 1800)
  }

  func testAudioSettingsAreStereoAAC() {
    // M5.7: the audio writer-input settings — AAC, 48 kHz stereo (SCStream
    // delivers 48 kHz audio).
    let settings = Recorder.audioSettings()
    XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC)
    XCTAssertEqual(settings[AVNumberOfChannelsKey] as? Int, 2)
    XCTAssertEqual(settings[AVSampleRateKey] as? Int, 48_000)
  }
}
