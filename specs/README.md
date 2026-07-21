# specs/

Short planning documents — one per feature or non-trivial change. The point is
**plan before code**: writing the approach down first keeps an agent (and you)
from wandering, and gives a clear definition of "done" to verify against.

For XPlain, this folder also holds the **per-release manual QA checklist** (the
real-time / visual behaviors that can't be automated — see `docs/testing.md`).

## How to use it

Before building something non-trivial, drop a file here named after the feature
(e.g. `draw-shapes.md`). Keep it to a screen or less. A good spec answers:

- **What** — the change in one or two sentences.
- **Approach** — how it'll be done; key files or modules touched (reference the
  components in `docs/core.md`).
- **Done when** — the observable result that means it's finished (a passing test, a
  working mode, a rendered overlay, a saved recording).

Then follow Explore → Plan → Code → Verify: implement against the spec and
`docs/plan.md`, and run the validation gates in `AGENTS.md` before calling it done.

## Template

```markdown
# <Feature name>

**What:** <one or two sentences>

**Approach:** <how; components from docs/core.md involved>

**Done when:** <observable success condition; link the relevant spec.md section
and success-criteria.md checkbox>
```

Specs are cheap and disposable. Once a feature ships, the spec can stay as a record
or be deleted — whichever keeps the folder useful rather than cluttered.
