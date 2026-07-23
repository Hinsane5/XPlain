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
    // Re-check the sibling items so the menu reflects the new selection.
    for item in sender.menu?.items ?? [] {
      item.state = (item === sender) ? .on : .off
    }
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

  /// M5.5: begins recording the display under the cursor to a timestamped mp4 in
  /// `~/Movies/XPlain`. No overlay — Record captures the live screen while you
  /// keep using it. Stopped by leaving Record (see `stopRecording`).
  private func startRecording() {
    guard let display = NSScreen.displayUnderCursor() else { return }
    let url = Recorder.defaultSaveDirectory
      .appendingPathComponent(Recorder.timestampedFilename())
    Task { [recorder] in
      do {
        try await recorder.start(of: display.displayID, pixelSize: display.pixelSize, to: url)
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
