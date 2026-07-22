import Cocoa

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
    modeController.onChange = { [overlay] from, next in
      NSLog("XPlain: \(from) → \(next)")
      if next == .idle {
        overlay.hide()
      } else {
        overlay.show(onDisplayFrame: NSScreen.frameUnderCursor())
      }
    }
    // M1.5: Esc / right-click on the overlay routes back to Idle.
    overlay.onDismissRequested = { [modeController] in
      modeController.exit()
    }
    let service = HotkeyService { [modeController] mode in
      modeController.request(mode)
    }
    service.start()
    hotkeys = service
  }
}
