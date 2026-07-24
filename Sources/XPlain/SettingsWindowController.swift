import AppKit
import SwiftUI

/// Owns the single Settings window (M6.2), hosting `SettingsView` (SwiftUI) in a
/// titled `NSWindow`. XPlain is a menu-bar agent, so opening activates the app
/// and brings the window front; the window is reused across opens and simply
/// hidden on close (not released), so reopening restores it.
final class SettingsWindowController {
  private var window: NSWindow?

  /// Shows the Settings window, creating it on first open and reusing it after.
  func show() {
    if window == nil {
      window = makeWindow()
    }
    NSApp.activate(ignoringOtherApps: true)
    window?.center()
    window?.makeKeyAndOrderFront(nil)
  }

  private func makeWindow() -> NSWindow {
    let hosting = NSHostingController(rootView: SettingsView())
    let window = NSWindow(contentViewController: hosting)
    window.title = "XPlain Settings"
    window.styleMask = [.titled, .closable]
    window.isReleasedWhenClosed = false  // reuse across opens
    window.setContentSize(NSSize(width: 520, height: 360))
    return window
  }
}
