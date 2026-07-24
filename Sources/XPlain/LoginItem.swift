import ServiceManagement

/// Registers/unregisters XPlain as a login item (M6.5) via `SMAppService`
/// (macOS 13+), so the menu-bar agent can start automatically at login. The
/// registration itself is the source of truth — `isEnabled` reads the live
/// service status rather than a persisted flag.
enum LoginItem {
  /// Whether XPlain is currently registered to launch at login.
  static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  /// Registers or unregisters the login item, throwing if the service call fails.
  static func setEnabled(_ enabled: Bool) throws {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }
}
