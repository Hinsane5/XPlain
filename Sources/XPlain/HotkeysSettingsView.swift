import KeyboardShortcuts
import SwiftUI

/// The Settings ▸ Hotkeys pane (M6.3): a `KeyboardShortcuts.Recorder` per mode,
/// with a live warning when the chosen chord collides with a known macOS system
/// shortcut. Rebinding takes effect immediately — the same `KeyboardShortcuts`
/// registration `HotkeyService` listens on — so no restart is needed.
struct HotkeysSettingsView: View {
  private struct Row: Identifiable {
    let id: String
    let label: String
    let name: KeyboardShortcuts.Name
  }

  private static let rows: [Row] = [
    Row(id: "zoom", label: "Zoom", name: .zoom),
    Row(id: "draw", label: "Draw", name: .draw),
    Row(id: "liveZoom", label: "LiveZoom", name: .liveZoom),
    Row(id: "record", label: "Record", name: .record),
  ]

  @State private var conflicts: [String: String] = [:]

  var body: some View {
    Form {
      ForEach(Self.rows) { row in
        VStack(alignment: .leading, spacing: 2) {
          KeyboardShortcuts.Recorder(row.label, name: row.name) { shortcut in
            conflicts[row.id] = Self.conflictName(for: shortcut)
          }
          if let conflict = conflicts[row.id] {
            Label("Conflicts with \(conflict)", systemImage: "exclamationmark.triangle.fill")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }
      }
    }
    .padding()
    .onAppear(perform: refreshConflicts)
  }

  private func refreshConflicts() {
    for row in Self.rows {
      conflicts[row.id] = Self.conflictName(for: KeyboardShortcuts.getShortcut(for: row.name))
    }
  }

  private static func conflictName(for shortcut: KeyboardShortcuts.Shortcut?) -> String? {
    guard let shortcut else { return nil }
    return HotkeyConflict.name(
      carbonKeyCode: shortcut.carbonKeyCode,
      modifiers: shortcut.modifiers
    )
  }
}
