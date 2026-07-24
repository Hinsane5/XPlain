import Cocoa
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var hotkeys: HotkeyService?
  private let modeController = ModeController()
  private let overlay = OverlayController()
  private let recorder = Recorder()  // M5.5

  /// Recording HUD state (M5.9): the start time and the once-a-second timer that
  /// refreshes the menu-bar elapsed clock. Both nil when not recording.
  private var recordingStartDate: Date?
  private var recordingTimer: Timer?
  /// The idle menu-bar title, restored when recording stops.
  private static let idleStatusTitle = "X"

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.title = Self.idleStatusTitle

    let menu = NSMenu()
    menu.addItem(makeLiveZoomFollowMenuItem())  // M5.4
    menu.addItem(makeRecordingScopeMenuItem())  // M5.6
    menu.addItem(makeSystemAudioMenuItem())  // M5.7
    menu.addItem(makeMicrophoneMenuItem())  // M5.7b
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
      )
    )
    item.menu = menu

    statusItem = item

    // M1.3+: hotkeys drive the mode controller, which shows/hides the overlay
    // per mode (see `enter`). Entering idle tears the overlay down.
    modeController.onChange = { [weak self] from, next in
      NSLog("XPlain: \(from) → \(next)")
      self?.transition(from: from, to: next)
    }
    // M1.5: Esc / right-click on the overlay routes back to Idle.
    overlay.onDismissRequested = { [modeController] in
      modeController.exit()
    }
    // M2.2: gate activation on Screen Recording permission — denied requests
    // resolve to .permissionPrompt instead of a blank/failed capture.
    let service = HotkeyService { [weak self, modeController] mode in
      // M5.8: recording is a background activity, not an exclusive mode — ⌘⌃R
      // toggles it independently so you can Zoom/Draw *while* recording and
      // those overlays are composited into the file (SCStream captures the whole
      // display). All the other hotkeys drive the exclusive mode machine.
      if mode == .record {
        self?.toggleRecording()
        return
      }
      let resolved = ModeActivationGate.resolve(
        requested: mode,
        permissionGranted: Self.requestScreenRecordingAccessIfNeeded()
      )
      // Toggle, not request: pressing a mode's hotkey while already in it exits.
      // This is the only way out of click-through LiveZoom (M5.3), where Esc /
      // right-click pass through to the app underneath.
      modeController.toggle(resolved)
    }
    service.start()
    hotkeys = service
  }

  /// Presents the overlay content for a mode transition. Draw has two entry
  /// paths (M4.9): from Zoom it annotates the current magnified image
  /// (`drawOverCurrent`); standalone it freezes a fresh 1× capture.
  private func transition(from: Mode, to next: Mode) {
    if next == .draw, from == .zoom {
      overlay.drawOverCurrent()
      return
    }
    switch next {
    case .idle:
      overlay.hide()
    case .permissionPrompt:
      overlay.showPermissionPrompt(onDisplayFrame: NSScreen.frameUnderCursor())
    case .zoom:
      withDisplayUnderCursor {
        overlay.showCapturedSnapshot(of: $0, magnifiedBy: ZoomRenderer.defaultScale)
      }
    case .draw:
      // M4.2: freeze the screen as a backdrop and draw annotations over it.
      withDisplayUnderCursor { overlay.showDrawing(of: $0) }
    case .liveZoom:
      // M5.2: continuously-updating magnified view of the live screen.
      withDisplayUnderCursor { overlay.showLiveZoom(of: $0) }
    case .record:
      // M5.8: Record is no longer an exclusive mode — ⌘⌃R drives recording
      // directly (see `toggleRecording`), never routing through the mode
      // machine, so this case is unreachable.
      break
    }
  }

  /// M5.8: toggles background recording, independent of the exclusive mode
  /// machine. Gates on Screen Recording permission on start (routing a denial to
  /// the permission prompt), and stops+saves if already recording.
  private func toggleRecording() {
    if recorder.isRecording {
      stopRecording()
      return
    }
    guard Self.requestScreenRecordingAccessIfNeeded() else {
      modeController.request(.permissionPrompt)
      return
    }
    startRecording()
  }

  /// M5.5/M5.6: begins recording the display under the cursor to a timestamped
  /// mp4 in `~/Movies/XPlain`. Full-display scope records immediately with no
  /// overlay (you keep using the screen); region scope first shows a drag-select
  /// overlay, then records just that rectangle. Stopped by leaving Record.
  private func startRecording() {
    guard let display = NSScreen.displayUnderCursor() else { return }
    switch SettingsStore.shared.recordingScope {
    case .fullDisplay:
      beginRecording(display: display, pixelSize: display.pixelSize, sourceRect: nil)
    case .selectedRegion:
      overlay.selectRegion(of: display) { [weak self] rect in
        guard let self else { return }
        guard let region = rect.map({ RecordingRegion.clamped($0, to: display.frame.size) }),
          RecordingRegion.isUsable(region)
        else {
          // Cancelled or too small — just don't record (recording isn't a mode).
          return
        }
        self.beginRecording(
          display: display,
          pixelSize: RecordingRegion.pixelSize(
            selection: region,
            scale: display.backingScaleFactor
          ),
          sourceRect: RecordingRegion.sourceRect(
            selection: region,
            displayHeightPoints: display.frame.height
          )
        )
      }
    }
  }

  private func beginRecording(display: Display, pixelSize: CGSize, sourceRect: CGRect?) {
    let url = Recorder.defaultSaveDirectory
      .appendingPathComponent(Recorder.timestampedFilename())
    let systemAudio = SettingsStore.shared.capturesSystemAudio  // M5.7
    let microphone = SettingsStore.shared.capturesMicrophone  // M5.7b
    Task { [recorder, weak self] in
      do {
        try await recorder.start(
          of: display.displayID,
          pixelSize: pixelSize,
          to: url,
          sourceRect: sourceRect,
          capturesSystemAudio: systemAudio,
          capturesMicrophone: microphone
        )
        await MainActor.run { self?.startRecordingHUD() }  // M5.9
      } catch {
        NSLog("XPlain: recording failed to start - \(error)")
      }
    }
  }

  /// M5.5: stops the in-progress recording and logs the saved file path. Hides
  /// the HUD immediately (we're on the main thread from the hotkey callback) so
  /// the indicator disappears the moment you press stop, not after finalizing.
  private func stopRecording() {
    stopRecordingHUD()  // M5.9
    Task { [recorder] in
      do {
        let url = try await recorder.stop()
        NSLog("XPlain: saved recording \(url.path)")
      } catch {
        NSLog("XPlain: stop recording failed - \(error)")
      }
    }
  }

  // MARK: Recording HUD (M5.9)

  /// Starts the menu-bar recording indicator: a red dot plus an elapsed clock
  /// that ticks once a second.
  private func startRecordingHUD() {
    recordingStartDate = Date()
    updateRecordingHUD()
    let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      self?.updateRecordingHUD()
    }
    RunLoop.main.add(timer, forMode: .common)  // keep ticking during menu tracking
    recordingTimer = timer
  }

  /// Stops the indicator and restores the idle menu-bar title.
  private func stopRecordingHUD() {
    recordingTimer?.invalidate()
    recordingTimer = nil
    recordingStartDate = nil
    statusItem?.button?.attributedTitle = NSAttributedString(string: Self.idleStatusTitle)
  }

  private func updateRecordingHUD() {
    guard let recordingStartDate else { return }
    let elapsed = Date().timeIntervalSince(recordingStartDate)
    let title = NSMutableAttributedString(
      string: "● ",
      attributes: [.foregroundColor: NSColor.systemRed]
    )
    title.append(NSAttributedString(string: ElapsedTime.format(elapsed)))
    statusItem?.button?.attributedTitle = title
  }

  private func withDisplayUnderCursor(_ present: (Display) -> Void) {
    if let display = NSScreen.displayUnderCursor() {
      present(display)
    } else {
      overlay.show(onDisplayFrame: NSScreen.frameUnderCursor())
    }
  }

  /// `CGPreflightScreenCaptureAccess()` alone never prompts — if permission has
  /// never been decided, the user would be stuck reading our own in-app prompt
  /// forever with no way to grant it short of manually finding the right
  /// System Settings pane themselves. `CGRequestScreenCaptureAccess()` shows
  /// the real system dialog the first time (and returns immediately if the
  /// decision is already made either way), so try preflight first and only
  /// fall through to a real request if it's actually needed.
  private static func requestScreenRecordingAccessIfNeeded() -> Bool {
    CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
  }
}
