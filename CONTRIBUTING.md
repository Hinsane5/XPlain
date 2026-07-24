# Contributing to XPlain

Thanks for your interest in improving XPlain! This guide covers how to get set up
and the conventions the project follows.

## Getting set up

You'll need **Xcode 15+** on **macOS 14 (Sonoma)+**.

```bash
git clone https://github.com/Hinsane5/XPlain.git && cd XPlain
open XPlain.xcodeproj      # then Product ▸ Run
```

The Xcode project is generated from [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen). **After changing `project.yml`,
run `./scripts/generate-project.sh`** — don't edit the `.xcodeproj` by hand, and
don't run `xcodegen generate` directly (the script also patches the project format
for the CI toolchain; see its comment).

## Before you open a PR

Open an issue first to discuss anything non-trivial — it saves everyone time.

Every change must keep the **validation gates** green:

```bash
swiftlint --strict
swift-format lint --recursive Sources Tests
xcodebuild -scheme XPlain -destination 'platform=macOS' build test
```

CI runs these on every push and pull request.

## Workflow — test first

XPlain is built test-first: **Explore → Plan → Test (red) → Code (green) → Refactor
→ Verify**. For any non-trivial change:

1. Write a short spec in [`specs/`](specs/) describing the behavior.
2. Write the failing test first (from the "Done when" of the task), and watch it fail.
3. Write the least code to make it pass, then refactor with the test green.

Capture-, GPU-, and recorder-bound paths that can't run in CI are verified against a
real screen and tracked in the `specs/*-manual-checklist.md` files. See
[docs/testing.md](docs/testing.md) for the full strategy and [docs/backlog.md](docs/backlog.md)
for the task tracker.

## Style

- **Swift 5.9**, formatted with `swift-format` and linted with `swiftlint --strict`
  (configs are in the repo root).
- Match the surrounding code's naming, comment density, and idioms. Comments should
  explain *why*, not restate *what*.
- Keep commits focused and their messages descriptive.

## Reporting bugs

Open an issue with your macOS version, what you did, what you expected, and what
happened. For crashes, include any relevant output from Console.app filtered to
`XPlain`.

## Code of conduct

Be respectful and constructive. This is a small project meant to be a pleasant place
to collaborate.
