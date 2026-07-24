import Foundation

/// Formats an elapsed duration for the recording HUD (M5.9). `M:SS` under an
/// hour, `H:MM:SS` at or above one. Fractional seconds truncate (the HUD ticks
/// once a second). Pure so it's unit-tested without the menu bar.
enum ElapsedTime {
  static func format(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    let secs = total % 60
    let mins = (total / 60) % 60
    let hours = total / 3600
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, mins, secs)
    }
    return String(format: "%d:%02d", mins, secs)
  }
}
