import SwiftUI

/// The SwiftUI preferences window content (spec §7). M6.2 stands up the shell —
/// a tab per settings group — and later tasks fill the panes: hotkey recorders
/// (M6.3) and the live-wired zoom/pen/recording/general controls (M6.4).
struct SettingsView: View {
  var body: some View {
    TabView {
      HotkeysSettingsView()
        .tabItem { Label("Hotkeys", systemImage: "keyboard") }
      ZoomSettingsView()
        .tabItem { Label("Zoom", systemImage: "plus.magnifyingglass") }
      PenSettingsView()
        .tabItem { Label("Pen", systemImage: "pencil.tip") }
      RecordingSettingsView()
        .tabItem { Label("Recording", systemImage: "record.circle") }
      GeneralSettingsView()
        .tabItem { Label("General", systemImage: "gearshape") }
    }
    .frame(width: 520, height: 360)
  }
}
