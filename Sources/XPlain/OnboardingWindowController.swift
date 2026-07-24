import AppKit
import SwiftUI

/// Owns the first-run onboarding window (M6.9), hosting `OnboardingView`. Marks
/// onboarding complete when the window is dismissed — whether via "Get Started"
/// or the close button — so it only appears once.
final class OnboardingWindowController: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  /// Called once when onboarding is dismissed, to persist that it's been seen.
  var onFinished: (() -> Void)?

  /// Shows the onboarding window, activating the (menu-bar agent) app first.
  func show() {
    if window == nil {
      let hosting = NSHostingController(
        rootView: OnboardingView(onDone: { [weak self] in self?.window?.close() })
      )
      let window = NSWindow(contentViewController: hosting)
      window.title = "Welcome to XPlain"
      window.styleMask = [.titled, .closable]
      window.isReleasedWhenClosed = false
      window.delegate = self
      self.window = window
    }
    NSApp.activate(ignoringOtherApps: true)
    window?.center()
    window?.makeKeyAndOrderFront(nil)
  }

  func windowWillClose(_ notification: Notification) {
    onFinished?()
    onFinished = nil  // fire exactly once
  }
}
