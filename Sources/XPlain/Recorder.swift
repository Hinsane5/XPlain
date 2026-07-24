import AVFoundation
import ScreenCaptureKit

/// Records a display to an H.264 `.mp4` (M5.5): an `SCStream` feeds screen
/// sample buffers straight into an `AVAssetWriter`. Start begins the stream and
/// opens the writer; stop finalizes the file and returns its URL. Requires
/// Screen Recording permission — callers preflight and route denial through the
/// permission prompt (M2.2), same as `CaptureService`.
///
/// The pure pieces (output location, filename, writer settings) are static so
/// they're unit-tested without touching capture hardware; the live path is
/// covered by specs/m5-manual-checklist.md.
final class Recorder: NSObject, SCStreamOutput {
  enum RecorderError: Error {
    /// No shareable display matches the given `CGDirectDisplayID`.
    case noMatchingDisplay
    /// The `AVAssetWriter` couldn't be created or started for the output URL.
    case writerSetupFailed
    /// `stop()` was called with no recording in progress.
    case notRecording
  }

  private let frameQueue = DispatchQueue(label: "com.howardgoh.XPlain.recorder")
  private let audioQueue = DispatchQueue(label: "com.howardgoh.XPlain.recorder.audio")
  private let micQueue = DispatchQueue(label: "com.howardgoh.XPlain.recorder.mic")
  private var stream: SCStream?
  private var writer: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  /// The system-audio writer input, present only when audio capture is on (M5.7).
  private var audioInput: AVAssetWriterInput?
  /// The microphone writer input, present only when mic capture is on (M5.7b).
  private var micInput: AVAssetWriterInput?
  /// The writer session opens on the first frame's timestamp, not at start()
  /// — SCStream PTS are on the host clock, and `AVAssetWriter` wants the session
  /// origin to match the first appended buffer. Guarded so it happens once.
  private var startedSession = false
  /// Serializes the one-time session start between the video and audio queues.
  private let stateLock = NSLock()
  private var outputURL: URL?

  /// Whether a recording is currently in progress.
  private(set) var isRecording = false

  /// Begins recording `displayID` at `pixelSize`, writing to `outputURL` (a
  /// `.mp4` path; its parent directory is created if needed). Throws before any
  /// frame is captured if the display is unknown or the writer can't be set up.
  /// - Parameters:
  ///   - pixelSize: output frame size in native pixels (the region's size for a
  ///     cropped recording, or the whole display's).
  ///   - sourceRect: the display region to capture (points, top-left origin) for
  ///     region recording (M5.6); `nil` records the full display.
  ///   - capturesSystemAudio: when true, records the display's system audio into
  ///     an AAC track (M5.7). Covered by Screen Recording permission — no extra
  ///     prompt.
  ///   - capturesMicrophone: when true (and macOS 15+), records the default
  ///     microphone into its own AAC track (M5.7b). Prompts for mic permission
  ///     the first time; if denied or unavailable, recording proceeds without it.
  func start(
    of displayID: CGDirectDisplayID,
    pixelSize: CGSize,
    to outputURL: URL,
    sourceRect: CGRect? = nil,
    capturesSystemAudio: Bool = false,
    capturesMicrophone: Bool = false,
    quality: RecordingQuality = .high,
    excludingWindow windowID: CGWindowID? = nil
  ) async throws {
    let content = try await SCShareableContent.current
    guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
      throw RecorderError.noMatchingDisplay
    }

    // Mic is macOS 15+ (SCStream microphone capture) and needs its own TCC grant,
    // requested lazily here. A denial just drops the mic, not the recording.
    var micEnabled = false
    if capturesMicrophone {
      micEnabled = await Self.microphoneAvailable()
    }

    try Self.prepareOutputDirectory(for: outputURL)
    let (writer, input) = try Self.makeWriter(
      to: outputURL,
      width: Int(pixelSize.width),
      height: Int(pixelSize.height),
      quality: quality
    )
    self.writer = writer
    videoInput = input
    self.outputURL = outputURL
    startedSession = false

    if capturesSystemAudio {
      audioInput = addedAudioInput(to: writer)
    }
    if micEnabled {
      micInput = addedAudioInput(to: writer)
    }

    let excluded = content.windows.filter { $0.windowID == windowID }
    let filter = SCContentFilter(display: display, excludingWindows: excluded)
    let config = SCStreamConfiguration()
    if let sourceRect {
      config.sourceRect = sourceRect  // M5.6: crop to the selected region
    }
    config.width = Int(pixelSize.width)
    config.height = Int(pixelSize.height)
    config.showsCursor = true
    config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
    config.capturesAudio = capturesSystemAudio  // M5.7
    if micEnabled, #available(macOS 15.0, *) {
      config.captureMicrophone = true  // M5.7b
    }

    let stream = SCStream(filter: filter, configuration: config, delegate: nil)
    try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameQueue)
    if capturesSystemAudio {
      try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
    }
    if micEnabled, #available(macOS 15.0, *) {
      try stream.addStreamOutput(self, type: .microphone, sampleHandlerQueue: micQueue)
    }
    try await stream.startCapture()
    self.stream = stream
    isRecording = true
  }

  /// Makes an AAC audio input and adds it to `writer`, returning it — or `nil` if
  /// the writer rejects it. Shared by the system-audio and microphone tracks.
  private func addedAudioInput(to writer: AVAssetWriter) -> AVAssetWriterInput? {
    let input = Self.makeAudioInput()
    guard writer.canAdd(input) else { return nil }
    writer.add(input)
    return input
  }

  /// Requests microphone access (lazy TCC prompt) and reports whether mic capture
  /// is usable — macOS 15+ and access granted.
  private static func microphoneAvailable() async -> Bool {
    guard #available(macOS 15.0, *) else { return false }
    return await AVCaptureDevice.requestAccess(for: .audio)
  }

  /// Stops capture, finalizes the file, and returns the written URL. Throws
  /// `notRecording` if nothing is in progress.
  @discardableResult
  func stop() async throws -> URL {
    guard isRecording, let writer, let videoInput, let outputURL else {
      throw RecorderError.notRecording
    }
    isRecording = false
    try? await stream?.stopCapture()
    stream = nil

    // Hold the last frame until the real (wall-clock) stop time. SCStream only
    // emits a frame when the captured content *changes*, so a mostly-static
    // region delivers a few frames up front and then nothing — without this the
    // file's duration would be ~0s (last PTS − first PTS) instead of the true
    // recording length. `endSession` extends the timeline to `endTime`.
    let endTime = CMClockGetTime(CMClockGetHostTimeClock())
    videoInput.markAsFinished()
    audioInput?.markAsFinished()
    micInput?.markAsFinished()
    if writer.status == .writing {
      writer.endSession(atSourceTime: endTime)
    }
    await writer.finishWriting()
    self.writer = nil
    self.videoInput = nil
    self.audioInput = nil
    self.micInput = nil
    self.outputURL = nil
    return outputURL
  }

  // MARK: SCStreamOutput

  func stream(
    _ stream: SCStream,
    didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard isRecording, sampleBuffer.isValid, let writer else { return }
    if type == .screen {
      guard Self.isCompleteFrame(sampleBuffer), let videoInput else { return }
      appendFrame(sampleBuffer, to: videoInput, writer: writer)
    } else if type == .audio {
      guard let audioInput else { return }
      appendFrame(sampleBuffer, to: audioInput, writer: writer)
    } else if #available(macOS 15.0, *), type == .microphone {
      guard let micInput else { return }
      appendFrame(sampleBuffer, to: micInput, writer: writer)
    }
  }

  /// Appends one sample buffer, opening the writer session on the first buffer of
  /// any type (video or audio may arrive first). Serialized under `stateLock` so
  /// the video and audio queues don't race to start the session.
  private func appendFrame(
    _ sampleBuffer: CMSampleBuffer,
    to input: AVAssetWriterInput,
    writer: AVAssetWriter
  ) {
    stateLock.lock()
    if !startedSession {
      guard writer.status == .unknown, writer.startWriting() else {
        stateLock.unlock()
        return
      }
      writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
      startedSession = true
    }
    stateLock.unlock()

    guard writer.status == .writing, input.isReadyForMoreMediaData else { return }
    input.append(sampleBuffer)
  }

  // MARK: Pure helpers (unit-tested)

  /// The default recording folder, `~/Movies/XPlain` (spec §6).
  static var defaultSaveDirectory: URL {
    let movies =
      FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
      ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies")
    return movies.appendingPathComponent("XPlain")
  }

  /// A timestamped mp4 filename, e.g. `XPlain 2026-07-23 at 14.30.05.mp4`.
  static func timestampedFilename(date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
    return "XPlain \(formatter.string(from: date)).mp4"
  }

  /// The H.264 writer-input settings for the given native pixel size and quality
  /// (M6.4). Quality sets the average bitrate as bits-per-pixel × pixels × 60fps.
  static func videoSettings(
    width: Int,
    height: Int,
    quality: RecordingQuality = .high
  ) -> [String: Any] {
    let bitrate = Int(Double(width * height) * 60 * quality.bitsPerPixel)
    return [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate],
    ]
  }

  /// The AAC audio writer-input settings (M5.7). 48 kHz stereo matches what
  /// `SCStream` delivers for system audio.
  static func audioSettings() -> [String: Any] {
    [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 48_000,
      AVNumberOfChannelsKey: 2,
      AVEncoderBitRateKey: 128_000,
    ]
  }

  /// A real-time AAC audio writer input for the system-audio track (M5.7).
  private static func makeAudioInput() -> AVAssetWriterInput {
    let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings())
    input.expectsMediaDataInRealTime = true
    return input
  }

  /// Whether an `SCStream` sample buffer carries a real, complete frame (status
  /// `.complete`) rather than an idle/blank status update that has no image.
  private static func isCompleteFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
    guard
      let attachments = CMSampleBufferGetSampleAttachmentsArray(
        sampleBuffer,
        createIfNecessary: false
      ) as? [[SCStreamFrameInfo: Any]],
      let statusRaw = attachments.first?[.status] as? Int,
      let status = SCFrameStatus(rawValue: statusRaw)
    else { return false }
    return status == .complete
  }

  private static func prepareOutputDirectory(for url: URL) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    // AVAssetWriter refuses to overwrite; clear any stale file at the URL.
    try? FileManager.default.removeItem(at: url)
  }

  private static func makeWriter(
    to url: URL,
    width: Int,
    height: Int,
    quality: RecordingQuality
  ) throws -> (AVAssetWriter, AVAssetWriterInput) {
    guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
      throw RecorderError.writerSetupFailed
    }
    let input = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: videoSettings(width: width, height: height, quality: quality)
    )
    input.expectsMediaDataInRealTime = true
    guard writer.canAdd(input) else { throw RecorderError.writerSetupFailed }
    writer.add(input)
    return (writer, input)
  }
}
