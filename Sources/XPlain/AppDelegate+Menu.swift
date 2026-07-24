import Cocoa

/// The status-bar menu construction (M5.4–M5.7b): the LiveZoom-follow and
/// recording-scope submenus and the audio toggles, split out of `AppDelegate` to
/// keep it focused on lifecycle and mode/recording orchestration. The
/// `make…MenuItem` builders are `internal` so `applicationDidFinishLaunching` can
/// assemble the menu; the `@objc` actions stay file-private (selector dispatch
/// finds them by name regardless).
extension AppDelegate {
  /// The "LiveZoom Follow" submenu (M5.4): one item per follow mode with a
  /// checkmark on the active one, letting the user switch cursor-centered vs.
  /// edge-push. Selection persists via `SettingsStore`.
  func makeLiveZoomFollowMenuItem() -> NSMenuItem {
    let parent = NSMenuItem(title: "LiveZoom Follow", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    let active = SettingsStore.shared.liveZoomFollowMode
    for mode in LiveZoomFollow.Mode.allCases {
      let item = NSMenuItem(
        title: mode.title,
        action: #selector(selectLiveZoomFollowMode(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = mode.rawValue
      item.state = (mode == active) ? .on : .off
      submenu.addItem(item)
    }
    parent.submenu = submenu
    return parent
  }

  @objc fileprivate func selectLiveZoomFollowMode(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let mode = LiveZoomFollow.Mode(rawValue: raw)
    else { return }
    SettingsStore.shared.liveZoomFollowMode = mode
    checkOnly(sender)
  }

  /// The "Recording Scope" submenu (M5.6): full display vs. selected region,
  /// checkmark on the active one. Selection persists via `SettingsStore`.
  func makeRecordingScopeMenuItem() -> NSMenuItem {
    let parent = NSMenuItem(title: "Recording Scope", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    let active = SettingsStore.shared.recordingScope
    for scope in RecordingScope.allCases {
      let item = NSMenuItem(
        title: scope.title,
        action: #selector(selectRecordingScope(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = scope.rawValue
      item.state = (scope == active) ? .on : .off
      submenu.addItem(item)
    }
    parent.submenu = submenu
    return parent
  }

  @objc fileprivate func selectRecordingScope(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let scope = RecordingScope(rawValue: raw)
    else { return }
    SettingsStore.shared.recordingScope = scope
    checkOnly(sender)
  }

  /// The "Record System Audio" toggle (M5.7): a checkable item persisted in
  /// `SettingsStore`. Off by default; covered by Screen Recording permission.
  func makeSystemAudioMenuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Record System Audio",
      action: #selector(toggleSystemAudio(_:)),
      keyEquivalent: ""
    )
    item.target = self
    item.state = SettingsStore.shared.capturesSystemAudio ? .on : .off
    return item
  }

  @objc fileprivate func toggleSystemAudio(_ sender: NSMenuItem) {
    let enabled = !SettingsStore.shared.capturesSystemAudio
    SettingsStore.shared.capturesSystemAudio = enabled
    sender.state = enabled ? .on : .off
  }

  /// The "Record Microphone" toggle (M5.7b): a checkable item persisted in
  /// `SettingsStore`. Off by default; prompts for mic permission on first record.
  func makeMicrophoneMenuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Record Microphone",
      action: #selector(toggleMicrophone(_:)),
      keyEquivalent: ""
    )
    item.target = self
    item.state = SettingsStore.shared.capturesMicrophone ? .on : .off
    return item
  }

  @objc fileprivate func toggleMicrophone(_ sender: NSMenuItem) {
    let enabled = !SettingsStore.shared.capturesMicrophone
    SettingsStore.shared.capturesMicrophone = enabled
    sender.state = enabled ? .on : .off
  }

  /// Puts the checkmark on `sender` and clears its siblings, so a radio-style
  /// submenu reflects the new selection.
  fileprivate func checkOnly(_ sender: NSMenuItem) {
    for item in sender.menu?.items ?? [] {
      item.state = (item === sender) ? .on : .off
    }
  }
}
