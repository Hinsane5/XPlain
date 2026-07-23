import Cocoa

/// Shows and hides the single overlay window in response to mode changes. One
/// overlay exists at a time; switching between active modes (e.g. Zoom→Draw)
/// reuses it, and returning to idle tears it down.
final class OverlayController {
  private var window: OverlayWindow?

  /// Bumped by every mode-entry/exit so an in-flight async capture that finishes
  /// *after* the user already moved on (pressed Esc, switched modes) is dropped
  /// instead of popping a stale overlay onto the screen. See `showCapturedSnapshot`.
  private var generation = 0

  /// Called when the on-screen overlay reports an Esc / right-click dismissal
  /// request (M1.5). Set this before calling `show`.
  var onDismissRequested: (() -> Void)?

  /// The live capture feed while in LiveZoom, retained so it can be stopped on
  /// exit (M5.2). nil otherwise.
  private var liveSession: LiveCaptureSession?

  /// Whether an overlay is currently on screen.
  var isShowing: Bool { window != nil }

  /// Shows an overlay covering the given display frame, reusing the current
  /// window if one is already up (just repositioning it).
  func show(onDisplayFrame frame: NSRect) {
    if let window {
      window.setFrame(frame, display: true)
    } else {
      let overlay = OverlayWindow(displayFrame: frame)
      overlay.onDismissRequested = { [weak self] in self?.onDismissRequested?() }
      // XPlain is a menu-bar agent (LSUIElement), so it isn't the active app
      // when a hotkey fires — makeKeyAndOrderFront alone won't make the overlay
      // key, and a non-key window's cursor rects don't apply (the red-dot
      // cursor wouldn't show until you clicked). Activate first.
      NSApp.activate(ignoringOtherApps: true)
      overlay.makeKeyAndOrderFront(nil)
      window = overlay
    }
  }

  /// Removes the overlay, if any, and stops any live capture.
  func hide() {
    generation &+= 1
    stopLiveSession()
    window?.orderOut(nil)
    window = nil
  }

  /// LiveZoom (M5.2): shows a click-through-later overlay with a continuously
  /// updating magnified view of the live screen, excluding the overlay itself
  /// from the capture so it doesn't feed back.
  func showLiveZoom(of display: Display) {
    generation &+= 1
    show(onDisplayFrame: display.frame)
    guard let window else { return }
    let view = window.showLiveZoom()
    view.scale = ZoomRenderer.defaultScale
    view.followMode = Preferences.liveZoomFollowMode  // M5.4
    let excludedWindow = CGWindowID(window.windowNumber)

    stopLiveSession()
    let session = LiveCaptureSession { [weak view] frame in view?.update(frame: frame) }
    liveSession = session
    Task {
      do {
        try await session.start(
          of: display.displayID,
          pixelSize: display.pixelSize,
          excludingWindow: excludedWindow
        )
      } catch {
        NSLog("XPlain: live capture failed - \(error)")
      }
    }
  }

  private func stopLiveSession() {
    guard let session = liveSession else { return }
    liveSession = nil
    Task { await session.stop() }
  }

  /// Shows the overlay with the Screen Recording permission prompt (M2.2)
  /// instead of a mode's real content.
  func showPermissionPrompt(onDisplayFrame frame: NSRect) {
    generation &+= 1
    show(onDisplayFrame: frame)
    window?.showPermissionPrompt()
  }

  /// Draw-over-zoom (M4.9): keep the current (magnified) overlay content and draw
  /// on it, instead of re-capturing. No-op if no overlay is up.
  func drawOverCurrent() {
    generation &+= 1  // cancel any in-flight capture
    window?.beginDrawingOverCurrentContent()
  }

  /// Draw mode (M4.2): captures the display as a frozen backdrop, then shows the
  /// annotation canvas over it. Same capture-first + generation-guard structure
  /// as `showCapturedSnapshot`; falls back to the permission prompt on failure.
  func showDrawing(of display: Display) {
    generation &+= 1
    let gen = generation
    Task { @MainActor [weak self] in
      do {
        let image = try await CaptureService.snapshot(
          of: display.displayID,
          pixelSize: display.pixelSize
        )
        guard let self, self.generation == gen else { return }
        self.show(onDisplayFrame: display.frame)
        self.window?.showAnnotationCanvas(backdrop: image)
      } catch {
        NSLog("XPlain: capture failed - \(error)")
        guard let self, self.generation == gen else { return }
        self.show(onDisplayFrame: display.frame)
        self.window?.showPermissionPrompt()
      }
    }
  }

  /// Captures the display first, *then* shows the overlay already holding the
  /// real desktop image (M2.4). Capturing before the window appears is what
  /// keeps our own translucent overlay out of the screenshot — showing first
  /// would let `SCScreenshotManager` grab the overlay too, baking a ghost layer
  /// into the "frozen" image. Falls back to the permission prompt if capture
  /// fails (e.g. permission revoked after `AppDelegate`'s preflight).
  ///
  /// The `generation` guard drops the result if the user already dismissed or
  /// switched modes during the async capture, so a late frame never pops a stale
  /// overlay back onto the screen.
  func showCapturedSnapshot(of display: Display, magnifiedBy scale: CGFloat = 1) {
    generation &+= 1
    let gen = generation
    // Cursor in the window's (bottom-left) space: global mouse minus the
    // display's origin. This is the zoom center handed to ZoomRenderer (M3.1).
    let mouse = NSEvent.mouseLocation
    let cursor = CGPoint(x: mouse.x - display.frame.minX, y: mouse.y - display.frame.minY)
    Task { @MainActor [weak self] in
      do {
        let image = try await CaptureService.snapshot(
          of: display.displayID,
          pixelSize: display.pixelSize
        )
        guard let self, self.generation == gen else { return }
        self.show(onDisplayFrame: display.frame)
        self.window?.showImage(image, magnifiedBy: scale, about: cursor, animated: scale != 1)
      } catch {
        NSLog("XPlain: capture failed - \(error)")
        guard let self, self.generation == gen else { return }
        self.show(onDisplayFrame: display.frame)
        self.window?.showPermissionPrompt()
      }
    }
  }
}

extension NSScreen {
  /// The frame of the display currently under the cursor, falling back to the
  /// main display. The selection itself is `DisplayTargeting.frame`, a pure
  /// function unit-tested in isolation (M1.6); this just supplies live inputs.
  static func frameUnderCursor() -> NSRect {
    DisplayTargeting.frame(
      at: NSEvent.mouseLocation,
      in: screens.map(\.frame),
      fallback: main?.frame
    ) ?? .zero
  }

  /// The `CGDirectDisplayID` ScreenCaptureKit needs to capture this screen.
  var displayID: CGDirectDisplayID? {
    (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
  }

  /// The display currently under the cursor, as a full `Display` (frame +
  /// capture identity), falling back to the main display (M2.4). The
  /// selection itself is `DisplayTargeting.display`, unit-tested in isolation;
  /// this just supplies live inputs.
  static func displayUnderCursor() -> Display? {
    DisplayTargeting.display(
      at: NSEvent.mouseLocation,
      in: screens.compactMap(\.asDisplay),
      fallback: main?.asDisplay
    )
  }

  private var asDisplay: Display? {
    displayID.map { Display(frame: frame, displayID: $0, backingScaleFactor: backingScaleFactor) }
  }
}
