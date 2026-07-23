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

    // M1.3: hotkeys drive the mode controller, which shows/hides the overlay on
    // the display under the cursor. Entering idle tears the overlay down.
    // M2.2: a permission-prompt "mode" shows different overlay content.
    // M2.4: real modes show the actual captured desktop, not a color fill.
    modeController.onChange = { [overlay] from, next in
      NSLog("XPlain: \(from) → \(next)")
      switch next {
      case .idle:
        overlay.hide()
      case .permissionPrompt:
        overlay.showPermissionPrompt(onDisplayFrame: NSScreen.frameUnderCursor())
      default:
        if let display = NSScreen.displayUnderCursor() {
          overlay.showCapturedSnapshot(of: display)
        } else {
          overlay.show(onDisplayFrame: NSScreen.frameUnderCursor())
        }
      }
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
