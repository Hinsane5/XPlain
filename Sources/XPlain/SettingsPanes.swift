import AppKit
import SwiftUI

/// The live-wired Settings panes (M6.4). Each control binds via `@AppStorage` to
/// the exact `UserDefaults` key `SettingsStore` reads, so changing it here takes
/// effect on the next mode activation — no restart. Defaults mirror
/// `SettingsStore`'s so an unset key shows the same value both places.

struct ZoomSettingsView: View {
  @AppStorage(SettingsStore.Key.initialZoomLevel.rawValue) private var level = 2.0
  @AppStorage(SettingsStore.Key.zoomStep.rawValue) private var step = 0.25
  @AppStorage(SettingsStore.Key.animateZoomIn.rawValue) private var animate = true

  var body: some View {
    Form {
      LabeledSlider(
        label: "Initial zoom level",
        value: $level,
        range: 1.25...8,
        step: 0.25,
        format: "%.2f×"
      )
      LabeledSlider(
        label: "Zoom step",
        value: $step,
        range: 0.05...1,
        step: 0.05,
        format: "%.2f×"
      )
      Toggle("Animate zoom-in", isOn: $animate)
    }
    .padding()
  }
}

struct PenSettingsView: View {
  @AppStorage(SettingsStore.Key.defaultPenColor.rawValue) private var color = PenColor.red
  @AppStorage(SettingsStore.Key.defaultPenWidth.rawValue) private var width = 3.0
  @AppStorage(SettingsStore.Key.highlighterOpacity.rawValue) private var opacity = 0.4
  @AppStorage(SettingsStore.Key.textFontSize.rawValue) private var textSize = 24.0

  var body: some View {
    Form {
      Picker("Default color", selection: $color) {
        ForEach(PenColor.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
      }
      LabeledSlider(label: "Default width", value: $width, range: 1...60, step: 1, format: "%.0f")
      LabeledSlider(
        label: "Highlighter opacity",
        value: $opacity,
        range: 0.1...1,
        step: 0.05,
        format: "%.2f"
      )
      LabeledSlider(
        label: "Text size",
        value: $textSize,
        range: 10...200,
        step: 1,
        format: "%.0f pt"
      )
    }
    .padding()
  }
}

struct RecordingSettingsView: View {
  @AppStorage(SettingsStore.Key.recordingScope.rawValue) private var scope = RecordingScope
    .fullDisplay
  @AppStorage(SettingsStore.Key.capturesSystemAudio.rawValue) private var systemAudio = false
  @AppStorage(SettingsStore.Key.capturesMicrophone.rawValue) private var microphone = false
  @AppStorage(SettingsStore.Key.recordingQuality.rawValue) private var quality = RecordingQuality
    .high
  @State private var folder = SettingsStore.shared.recordingFolder

  var body: some View {
    Form {
      Picker("Scope", selection: $scope) {
        ForEach(RecordingScope.allCases, id: \.self) { Text($0.title).tag($0) }
      }
      Picker("Quality", selection: $quality) {
        ForEach(RecordingQuality.allCases, id: \.self) { Text($0.title).tag($0) }
      }
      Toggle("System audio", isOn: $systemAudio)
      Toggle("Microphone", isOn: $microphone)
      HStack {
        Text("Folder:")
        Text(folder.path)
          .lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
        Spacer()
        Button("Choose…", action: chooseFolder)
      }
    }
    .padding()
  }

  private func chooseFolder() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.directoryURL = folder
    if panel.runModal() == .OK, let url = panel.url {
      SettingsStore.shared.recordingFolder = url
      folder = url
    }
  }
}

struct GeneralSettingsView: View {
  @AppStorage(SettingsStore.Key.activeDisplayTarget.rawValue)
  private var target = ActiveDisplayTarget.underCursor

  var body: some View {
    Form {
      Picker("Active display", selection: $target) {
        ForEach(ActiveDisplayTarget.allCases, id: \.self) { Text($0.title).tag($0) }
      }
      Text("Which display a mode targets when a hotkey fires.")
        .font(.caption).foregroundStyle(.secondary)
    }
    .padding()
  }
}

/// A slider with a label and a live value readout, shared by the panes.
private struct LabeledSlider: View {
  let label: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let format: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(label): \(String(format: format, value))")
      Slider(value: $value, in: range, step: step)
    }
  }
}
