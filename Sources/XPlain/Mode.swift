/// A screen mode XPlain can be in. `idle` is the resting state; the others are
/// activated by a global hotkey (see `HotkeyService`) and enforced one-at-a-time
/// by the mode controller (Milestone M1.2).
enum Mode: Equatable, CaseIterable {
  case idle
  case zoom
  case draw
  case liveZoom
  case record
}
