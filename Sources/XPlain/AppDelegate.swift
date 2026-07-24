import Cocoa
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var hotkeys: HotkeyService?
  private let modeController = ModeController()
  private let overlay = OverlayController()
  private let recorder = Recorder()  // M5.5

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.title = "X"

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
    let service = HotkeyService { [modeController] mode in
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

  /// The "LiveZoom Follow" submenu (M5.4): one item per follow mode with a
  /// checkmark on the active one, letting the user switch cursor-centered vs.
  /// edge-push. Selection persists via `Preferences`.
  private func makeLiveZoomFollowMenuItem() -> NSMenuItem {
    let parent = NSMenuItem(title: "LiveZoom Follow", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    let active = Preferences.liveZoomFollowMode
    for mode in LiveZoomFollow.Mode.allCases {
      let item = NSMenuItem(
        title: mode.title,
        action: #selector(selectLiveZoomFollowMode(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = mode.rawValue
      item.state = (mode == active) ? .on : .off
      submenu.addItem(item)
    }
    parent.submenu = submenu
    return parent
  }

  @objc private func selectLiveZoomFollowMode(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let mode = LiveZoomFollow.Mode(rawValue: raw)
    else { return }
    Preferences.liveZoomFollowMode = mode
    checkOnly(sender)
  }

  /// The "Recording Scope" submenu (M5.6): full display vs. selected region,
  /// checkmark on the active one. Selection persists via `Preferences`.
  private func makeRecordingScopeMenuItem() -> NSMenuItem {
    let parent = NSMenuItem(title: "Recording Scope", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    let active = Preferences.recordingScope
    for scope in RecordingScope.allCases {
      let item = NSMenuItem(
        title: scope.title,
        action: #selector(selectRecordingScope(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = scope.rawValue
      item.state = (scope == active) ? .on : .off
      submenu.addItem(item)
    }
    parent.submenu = submenu
    return parent
  }

  @objc private func selectRecordingScope(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let scope = RecordingScope(rawValue: raw)
    else { return }
    Preferences.recordingScope = scope
    checkOnly(sender)
  }

  /// Puts the checkmark on `sender` and clears its siblings, so a radio-style
  /// submenu reflects the new selection.
  private func checkOnly(_ sender: NSMenuItem) {
    for item in sender.menu?.items ?? [] {
      item.state = (item === sender) ? .on : .off
    }
  }

  /// The "Record System Audio" toggle (M5.7): a checkable item persisted in
  /// `Preferences`. Off by default; covered by Screen Recording permission.
  private func makeSystemAudioMenuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Record System Audio",
      action: #selector(toggleSystemAudio(_:)),
      keyEquivalent: ""
    )
    item.target = self
    item.state = Preferences.capturesSystemAudio ? .on : .off
    return item
  }

  @objc private func toggleSystemAudio(_ sender: NSMenuItem) {
    let enabled = !Preferences.capturesSystemAudio
    Preferences.capturesSystemAudio = enabled
    sender.state = enabled ? .on : .off
  }

  /// The "Record Microphone" toggle (M5.7b): a checkable item persisted in
  /// `Preferences`. Off by default; prompts for mic permission on first record.
  private func makeMicrophoneMenuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Record Microphone",
      action: #selector(toggleMicrophone(_:)),
      keyEquivalent: ""
    )
    item.target = self
    item.state = Preferences.capturesMicrophone ? .on : .off
    return item
  }

  @objc private func toggleMicrophone(_ sender: NSMenuItem) {
    let enabled = !Preferences.capturesMicrophone
    Preferences.capturesMicrophone = enabled
    sender.state = enabled ? .on : .off
  }

  /// Presents the overlay content for a mode transition. Draw has two entry
  /// paths (M4.9): from Zoom it annotates the current magnified image
  /// (`drawOverCurrent`); standalone it freezes a fresh 1× capture.
  private func transition(from: Mode, to next: Mode) {
    // M5.5: leaving Record stops and saves the file, whatever we move to next.
    if from == .record, next != .record {
      stopRecording()
    }
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
      // M5.5: record the live screen to an mp4 — no blocking overlay, so you
      // keep working while it captures (the HUD indicator lands in M5.9).
      startRecording()
    }
  }

  /// M5.5/M5.6: begins recording the display under the cursor to a timestamped
  /// mp4 in `~/Movies/XPlain`. Full-display scope records immediately with no
  /// overlay (you keep using the screen); region scope first shows a drag-select
  /// overlay, then records just that rectangle. Stopped by leaving Record.
  private func startRecording() {
    guard let display = NSScreen.displayUnderCursor() else { return }
    switch Preferences.recordingScope {
    case .fullDisplay:
      beginRecording(display: display, pixelSize: display.pixelSize, sourceRect: nil)
    case .selectedRegion:
      overlay.selectRegion(of: display) { [weak self] rect in
        guard let self else { return }
        guard let region = rect.map({ RecordingRegion.clamped($0, to: display.frame.size) }),
          RecordingRegion.isUsable(region)
        else {
          // Cancelled or too small — leave Record rather than record nothing.
          self.modeController.exit()
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
    let systemAudio = Preferences.capturesSystemAudio  // M5.7
    let microphone = Preferences.capturesMicrophone  // M5.7b
    Task { [recorder] in
      do {
        try await recorder.start(
          of: display.displayID,
          pixelSize: pixelSize,
          to: url,
          sourceRect: sourceRect,
          capturesSystemAudio: systemAudio,
          capturesMicrophone: microphone
        )
      } catch {
        NSLog("XPlain: recording failed to start - \(error)")
      }
    }
  }

  /// M5.5: stops the in-progress recording and logs the saved file path.
  private func stopRecording() {
    Task { [recorder] in
      do {
        let url = try await recorder.stop()
        NSLog("XPlain: saved recording \(url.path)")
      } catch {
        NSLog("XPlain: stop recording failed - \(error)")
      }
    }
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
