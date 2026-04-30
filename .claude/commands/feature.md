---
description: Plan and implement a Capitalo feature using Explore→Plan→Implement with TDD
argument-hint: <feature description>
---
You will implement: $ARGUMENTS

## Phase 1 — EXPLORE (read-only, no code)

- Read @CLAUDE.md, @docs/architecture.md, and relevant section of @docs/Capitalo_GDD.md
- Read affected `scripts/autoload/`, `scripts/classes/`, `scenes/` files
- Read related `data/*.json` if feature touches game data
- Check existing tests in `tests/`
- DO NOT write code. Output:
  - List of files to read and what each does
  - Current architecture summary for this area
  - Where new code goes (file paths) and why

## Phase 2 — PLAN (no code)

Output:
- **Files to create / modify** with one-line purpose each
- **Test cases first** — list GDScript test names that must pass (`tests/<Feature>Test.gd`)
- **EventBus signals** added/used (centralised in `scripts/autoload/EventBus.gd`)
- **GameState fields** added → reminder: update `to_dict()` AND `from_dict()`
- **BigNumber usage** — flag any place where money/income/cost crosses float boundary
- **Risks / unknowns** — explicit list
- **Out of scope** — what we're NOT doing

**WAIT for user approval before Phase 3.**

## Phase 3 — IMPLEMENT (after approval)

1. Write failing tests first → commit `test(<scope>): add failing tests for <feature>`
2. Implement minimal code → tests pass → `gdlint scripts/` clean
3. Run `godot --headless --check-only` and any relevant test scripts
4. If GameState changed: verify `to_dict()` / `from_dict()` round-trip
5. Commit with `/commit` (subject EN)
6. Summary: 2 sentences max — what changed, what's next
