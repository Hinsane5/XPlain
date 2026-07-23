import CoreImage
import ScreenCaptureKit

/// A live `SCStream` frame feed for a display (M5.1) — the continuous source
/// LiveZoom (M5.2) and Record (M5.5) draw from, versus `CaptureService.snapshot`'s
/// one-shot still. Delivers each frame as a `CGImage` on the main queue.
final class LiveCaptureSession: NSObject, SCStreamOutput {
  private let onFrame: (CGImage) -> Void
  private let ciContext = CIContext()
  private let frameQueue = DispatchQueue(label: "com.howardgoh.XPlain.livecapture")
  private var stream: SCStream?

  /// - Parameter onFrame: called on the main queue with each captured frame.
  init(onFrame: @escaping (CGImage) -> Void) {
    self.onFrame = onFrame
  }

  /// Starts streaming the given display at the requested pixel size. Frames flow
  /// to `onFrame` until `stop()`.
  func start(of displayID: CGDirectDisplayID, pixelSize: CGSize) async throws {
    let content = try await SCShareableContent.current
    guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
      throw CaptureService.CaptureError.noMatchingDisplay
    }

    let filter = SCContentFilter(display: display, excludingWindows: [])
    let config = SCStreamConfiguration()
    config.width = Int(pixelSize.width)
    config.height = Int(pixelSize.height)
    config.showsCursor = true  // the live magnified view should show the pointer
    config.minimumFrameInterval = CMTime(value: 1, timescale: 60)  // up to 60 fps

    let stream = SCStream(filter: filter, configuration: config, delegate: nil)
    try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameQueue)
    try await stream.startCapture()
    self.stream = stream
  }

  /// Stops streaming and releases the stream.
  func stop() async {
    try? await stream?.stopCapture()
    stream = nil
  }

  func stream(
    _ stream: SCStream,
    didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .screen, sampleBuffer.isValid,
      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }

    let ciImage = CIImage(cvImageBuffer: pixelBuffer)
    guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

    let deliver = onFrame
    DispatchQueue.main.async { deliver(cgImage) }
  }
}
