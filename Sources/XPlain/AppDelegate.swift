import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var hotkeys: HotkeyService?

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

    // M1.1: mode requests are logged for now; M1.2 routes them to the mode controller.
    let service = HotkeyService { mode in
      NSLog("XPlain: mode requested — \(mode)")
    }
    service.start()
    hotkeys = service
  }
}
