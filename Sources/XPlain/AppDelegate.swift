import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var hotkeys: HotkeyService?
  private let modeController = ModeController()

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

    // M1.2: hotkeys drive the mode controller; transitions are logged for now.
    // M1.3 will hook overlay windows onto `onChange`.
    modeController.onChange = { from, next in
      NSLog("XPlain: \(from) → \(next)")
    }
    let service = HotkeyService { [modeController] mode in
      modeController.request(mode)
    }
    service.start()
    hotkeys = service
  }
}
