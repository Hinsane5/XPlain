# Loop Guide — running the XPlain build loop

A self-contained playbook for **any coding agent** (e.g. a cheaper model like
Sonnet) to build XPlain autonomously, one backlog task at a time, without
rediscovering this project's quirks. Read this once at the start of a loop
session; it front-loads everything you need so you don't waste tokens.

If anything here conflicts with `AGENTS.md`, `AGENTS.md` wins — but this guide is
the operational detail for *looping specifically*.

---

## 0. TL;DR

Work the backlog **one `M<n>.<t>` task per iteration**, strictly test-first, run
the gates, commit, repeat. Stop at the end of the milestone or the first task you
can't finish alone (visual/permission/credential). Commits have **no co-author
trailer**. That's the whole job.

## 1. How to start the loop

In Claude Code, run this (dynamic / self-paced — no interval):

```
/loop Self-paced (dynamic) loop over the next milestone in docs/backlog.md. Each iteration: take the next unchecked task whose dependencies are met, follow the TDD flow (write the failing test first from docs/testing.md, implement, run the gates), commit per task with no co-author trailer, tick the checkbox. STOP the loop when the milestone is done, or at the first task that is manual-only / needs a permission/credential/decision I can't make. Do one task per iteration.
```

The `/loop` skill puts you in **dynamic mode**: do one task now, then call
`ScheduleWakeup` to continue.

- **Cadence:** there's no external signal to wait on (you are doing the work), so
  no Monitor is needed. Use `delaySeconds: 60` (the minimum) — each wake does a
  full task, it's not a poll.
- **Continue:** `ScheduleWakeup(delaySeconds: 60, prompt: "/loop <same prompt>", reason: "...")`.
- **Stop:** `ScheduleWakeup(stop: true)`.

You can also just work task-by-task across normal turns without `ScheduleWakeup`
— the per-task workflow below is what matters most.

## 2. The per-task loop (do this every iteration)

1. **Pick the task.** Open `docs/backlog.md`. Take the first `[ ]` task whose
   `Depends on` items are all `[x]` or `[~]`. Status markers: `[ ]` todo ·
   `[~]` in progress (code done, manual/visual check pending) · `[x]` done.
2. **Find its test.** Look up the task ID in the coverage matrix in
   `docs/testing.md` — it tells you the test type (`U`nit / `I`ntegration /
   `M`anual) and what to assert. Read the relevant `spec.md` / `core.md` section.
3. **RED — write the failing test first.** Add it under `Tests/XPlainTests/`,
   regenerate (step 6), and build. Confirm it **fails** (a compile error for a
   missing type counts as red). A test that never failed proves nothing.
4. **GREEN — implement.** Add code under `Sources/XPlain/`, wire it into
   `AppDelegate` if the task says so. Least code to pass.
5. **Format.** `swift-format format --in-place --recursive Sources Tests`
6. **Regenerate the Xcode project** (see §3 — REQUIRED whenever you add/remove a
   file): `./scripts/generate-project.sh`
7. **Run the gates:** `./scripts/verify-gates.sh --all` — must end
   `✅ all gates green`. Fix anything red and re-run; never proceed on red.
8. **Tick the checkbox** in `docs/backlog.md` (`[ ]`→`[x]`; use `[~]` if only a
   manual/visual check remains — see §7).
9. **Commit + push** (see §6).
10. **Next task or stop** (see §5).

## 3. Commands you'll actually run

```
./scripts/generate-project.sh                                   # regen Xcode proj (after add/remove files)
swift-format format --in-place --recursive Sources Tests        # auto-format
./scripts/verify-gates.sh --all                                 # lint + format-lint + build + test
swiftlint --strict                                              # just lint (to read violations)
xcodebuild -scheme XPlain -destination 'platform=macOS' build test   # just build+test
```

To see individual test results, pipe `xcodebuild ... test` through
`grep -E "Test Case.*(passed|failed)|Executed [0-9]+ tests, with"`.

## 4. Project gotchas — READ THESE (they cost real debugging time)

- **XcodeGen is the source of truth for the project.** The `.xcodeproj` is
  generated from `project.yml`. **After adding, removing, or renaming any file
  under `Sources/` or `Tests/`, run `./scripts/generate-project.sh`** or the new
  file won't be in the build. Use that script, **never** `xcodegen generate`
  directly — the script also patches `objectVersion 77→60` so CI's pinned
  Xcode 15.4 can open the project.
- **swift-format vs SwiftLint on trailing commas.** swift-format (603) *mandates*
  trailing commas in multi-line collection literals; SwiftLint's `trailing_comma`
  rule *forbids* them. It's already **disabled** in `.swiftlint.yml`. Always run
  `swift-format format --in-place` before the gates so formatting is normalized.
- **SwiftLint `--strict` rejects short identifiers.** Names of 1–2 chars (`to`,
  `x`, `y`) trip `identifier_name` (a warning that `--strict` turns into an
  error). Either avoid them or add the name to `identifier_name.excluded` in
  `.swiftlint.yml`. **M2.3 (Y-flip) and M3 (transforms) will need `x`/`y`** — add
  them to the excluded list when you get there.
- **Headless / CI test limits.** Test runs (and CI on `macos-14`) have **no
  Screen Recording permission and no attached GPU/display**. So:
  - Guard capture / `ScreenCaptureKit` / GPU / recorder tests with availability
    checks so they **skip**, never fail, when the resource is absent.
  - You can *construct* an `NSWindow` in a test and assert its properties; don't
    rely on actually *showing* it. Assert values (frames, transforms, model
    state), never "it looks right".
- **KeyboardShortcuts** is pinned at **1.9.4**. API you'll use:
  `KeyboardShortcuts.Name("x", default: .init(.z, modifiers: [.command, .control]))`,
  `name.defaultShortcut`, `KeyboardShortcuts.Shortcut(_ key: Key, modifiers:)`,
  `Key.z/.d/.l/.r`, `KeyboardShortcuts.onKeyDown(for:action:)`. The test target
  already has the package dependency (in `project.yml`) so `import
  KeyboardShortcuts` works in tests.
- **Coordinate systems** differ: AppKit is bottom-left origin, CGImage/SCK are
  top-left. Centralize the Y-flip once at the capture boundary (M2.3).
- **`ScheduleWakeup` delay** is clamped to `[60, 3600]`; `60` is the right cadence
  for this coding loop.

## 5. When to STOP the loop

Stop (and hand back to the user) when any is true:

- **Milestone complete** — all its tasks are `[x]` (or `[~]` pending only manual
  checks). Summarize and stop.
- **First task you can't finish alone:**
  - **Manual/visual acceptance** you can't verify (overlay appears, zoom looks
    smooth, recording plays back) — do the unit-testable core, mark `[~]`, add
    the visual step to the milestone's `specs/m*-manual-checklist.md`, and either
    batch it to milestone end or stop for the user to verify. **Ask the user
    which they prefer** if it's unclear.
  - **Permission/credential/decision** you don't have — e.g. M2.1/M5.x need real
    Screen Recording + a GPU on the user's machine; **M6.7/M6.8 need an Apple
    Developer account + Developer ID cert + notarization**; design choices. Stop
    and ask.

Stopping is normal — the user restarts the loop anytime.

## 6. Commit rules (important)

- **One commit per task.** Stage exactly what the task changed plus the
  regenerated `XPlain.xcodeproj/project.pbxproj` and the ticked `docs/backlog.md`.
- **Message format:**
  ```
  M<n>.<t>: <short title>

  <what changed, why; note the tests added and total test count>
  ```
- **NO `Co-Authored-By` trailer, and no Claude/Anthropic attribution.** This is a
  firm user preference. Commits are authored by the user only.
- Push to `origin/main` after each task (or per milestone). CI (`macos-14`) runs
  the same gates on push as a backstop.

## 7. Manual / visual tasks

Most feature tasks (M1.3–M1.5, M2.4, M3.x, M4.x, M5.x, M6.x) have BOTH a
unit-testable core and a visual/real-time acceptance. Handle them like this:

1. Implement the code + write the unit tests from the matrix; get the gates green.
2. Mark the task `[~]` in the backlog (not `[x]`).
3. Append the visual check to `specs/m<n>-manual-checklist.md` (create it if
   missing) as an unchecked item with concrete, observable steps.
4. Continue (batching visual checks to milestone end) or stop for the user to
   verify — per the user's stated preference.

Only the user flips a `[~]` manual item to `[x]`, after they verify it on a real
Mac.

## 8. Current state (update as you go)

- **M0** — ✅ done (toolchain, CI, menu-bar app).
- **M1.1** HotkeyService — ✅ done.
- **M1.2** ModeController — ✅ done.
- **M1.3** OverlayWindow — `[~]` code + unit tests done; visual check pending
  (`specs/m1-manual-checklist.md`).
- **Next up:** M1.4 (window level + Spaces), M1.5 (Esc/right-click exit), M1.6
  (display-targeting pure function + test — fully unit-testable, no manual part).

Keep this section honest; it's the fastest way for the next loop session to know
where to resume.

## 9. Reference map

- `docs/backlog.md` — the task queue (`M<n>.<t>`, deps, status).
- `docs/testing.md` — the per-task test matrix + TDD rules.
- `docs/spec.md` — what each mode/behavior should do.
- `docs/core.md` — architecture, components, the state machine.
- `AGENTS.md` — always-loaded index, commands, validation gates.
- `.claude/settings.json` — the Stop hook that auto-runs `verify-gates.sh`.
