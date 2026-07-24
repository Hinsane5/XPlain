import SwiftUI

/// The SwiftUI preferences window content (spec §7). M6.2 stands up the shell —
/// a tab per settings group — and later tasks fill the panes: hotkey recorders
/// (M6.3) and the live-wired zoom/pen/recording/general controls (M6.4).
struct SettingsView: View {
  var body: some View {
    TabView {
      placeholder("Hotkeys", "Rebind each mode's global shortcut. (M6.3)")
        .tabItem { Label("Hotkeys", systemImage: "keyboard") }
      placeholder("Zoom", "Initial level, step, and zoom-in animation. (M6.4)")
        .tabItem { Label("Zoom", systemImage: "plus.magnifyingglass") }
      placeholder("Pen", "Default color, width, highlighter opacity, text size. (M6.4)")
        .tabItem { Label("Pen", systemImage: "pencil.tip") }
      placeholder("Recording", "Output folder, scope, audio, quality. (M6.4)")
        .tabItem { Label("Recording", systemImage: "record.circle") }
      placeholder("General", "Launch at login, menu-bar icon, active display. (M6.4)")
        .tabItem { Label("General", systemImage: "gearshape") }
    }
    .frame(width: 520, height: 360)
  }

  private func placeholder(_ title: String, _ subtitle: String) -> some View {
    VStack(spacing: 8) {
      Text(title).font(.title2).bold()
      Text(subtitle).foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}
