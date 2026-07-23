import Cocoa
import CoreGraphics

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var hotkeys: HotkeyService?
  private let modeController = ModeController()
  private let overlay = OverlayController()

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.title = "X"

    let menu = NSMenu()
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
      self?.enter(next)
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
      modeController.request(resolved)
    }
    service.start()
    hotkeys = service
  }

  /// Presents the overlay content for a mode. Real modes capture the display
  /// under the cursor; a missing display falls back to a plain overlay.
  private func enter(_ mode: Mode) {
    switch mode {
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
    case .liveZoom, .record:
      // 1× frozen desktop for now (M5+).
      withDisplayUnderCursor { overlay.showCapturedSnapshot(of: $0) }
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
