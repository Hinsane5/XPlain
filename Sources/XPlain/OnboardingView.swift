import CoreGraphics
import KeyboardShortcuts
import SwiftUI

/// First-run onboarding (M6.9): welcomes a new user, walks them through granting
/// Screen Recording permission, and shows the hotkey cheat sheet — so a fresh
/// install reaches a working state. Shown once (see `SettingsStore
/// .hasCompletedOnboarding`).
struct OnboardingView: View {
  /// Called when the user dismisses onboarding ("Get Started").
  var onDone: () -> Void

  @State private var screenRecordingGranted = CGPreflightScreenCaptureAccess()

  private static let hotkeys: [(String, KeyboardShortcuts.Name)] = [
    ("Zoom", .zoom), ("Draw", .draw), ("LiveZoom", .liveZoom), ("Record", .record),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Welcome to XPlain").font(.largeTitle).bold()
      Text("Zoom into your screen, draw on it, and record it — with global hotkeys.")
        .foregroundStyle(.secondary)

      GroupBox("1 · Screen Recording permission") {
        HStack(spacing: 8) {
          Image(
            systemName: screenRecordingGranted
              ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
          )
          .foregroundStyle(screenRecordingGranted ? .green : .orange)
          Text(
            screenRecordingGranted
              ? "Granted — you're all set."
              : "Required to zoom, draw, and record. Grant it, then relaunch."
          )
          Spacer()
          if !screenRecordingGranted {
            Button("Open Settings") {
              NSWorkspace.shared.open(PermissionPromptContent.systemSettingsURL)
            }
          }
        }
        .padding(6)
      }

      GroupBox("2 · Hotkeys") {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(Self.hotkeys, id: \.0) { label, name in
            HStack {
              Text(label)
              Spacer()
              Text(KeyboardShortcuts.getShortcut(for: name)?.description ?? "—")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            }
          }
        }
        .padding(6)
      }
      Text("Change any of these in Settings ▸ Hotkeys.")
        .font(.caption).foregroundStyle(.secondary)

      HStack {
        Spacer()
        Button("Get Started", action: onDone).keyboardShortcut(.defaultAction)
      }
    }
    .padding(24)
    .frame(width: 460)
    .onAppear { screenRecordingGranted = CGPreflightScreenCaptureAccess() }
  }
}
