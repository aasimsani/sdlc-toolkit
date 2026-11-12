---
name: plan
description: SDLC stage 4. Turns the approved RFC's phases into an executable plan in plan mode, has EGM's implementation-readiness Goldfish check it, and commits docs/sdlc/<slug>/plan.md. Also adopts or reviews a plan someone else wrote. Use when the user runs /sdlc:plan or the sdlc skill routes here.
argument-hint: "<slug> [--adopt <path|url>] [--review]"
---

# Stage 4 — Plan

Read `${CLAUDE_PLUGIN_ROOT}/references/stage-rules.md` and `${CLAUDE_PLUGIN_ROOT}/references/tools.md` first.

The RFC says which phases and PRs exist. The plan says exactly which files change, in what order, with which test first. Planning happens in plan mode, where Claude can read the code but can't change it.

Feature: `$ARGUMENTS`

## Author mode

1. **Enter plan mode** with EnterPlanMode. Stop if the RFC isn't approved or skipped. When the RFC was skipped, take the design from the spec and the code.

2. **Read `spec.md`, the RFC and every file the change touches,** along with the tests around those files.

3. **Draft the plan** with the template's sections. Keep the RFC's phases and PR boundaries. Every acceptance criterion must map to a test.

4. **Challenge the plan.** Before showing it, take these two passes and fold the answers into the work order:
   - **Risk.** Ask what could break that the tests won't catch, and which step is riskiest.
   - **Size.** Run ponytail's ladder from `tools.md` on every new file, class, dependency and config option in the plan. Replace each one that fails the ladder with the smaller option it names, such as an existing helper, a standard library call, or nothing. Keep everything `spec.md` requires.

5. **Apply the stranger test.** Someone who has never seen this conversation should be able to implement the plan from the file alone.

6. **Present it** with ExitPlanMode. Revise until the engineer accepts it.

7. **Write `docs/sdlc/<slug>/plan.md`** after leaving plan mode.

8. **Gate.** The Goldfish review is `egm-review` with the `implementation` preset, using the inputs in `tools.md`. Commit `plan.md`, its report and `sdlc.yaml` together.

## Adopt and review modes

Follow `stage-rules.md`, using the same Goldfish review.

## Template

```markdown
# <Feature title> — plan

Verify command: `<from CLAUDE.md>`

## Files to change
| File | Change |
|---|---|
| `path/to/file` | <what changes and why> |

## Work order
Each phase starts with a failing test, then makes it pass, then cleans up. Each phase ends with a pr-review run.

### Phase 1 — <name> (PR 1 in the RFC; worktree: <name, or "main session">)
- [ ] Write a failing test for AC1 in `<test file>`
- [ ] Implement <thing> until the test passes
- [ ] Refactor, run the verify command, and run pr-review --local

### Phase 2 — <name> (depends on: Phase 1)
- [ ] ...

## Tests
| Acceptance criterion | Test |
|---|---|
| AC1 | `<test file>::<test name>` |

## Parallel work
<Name the phases that share no files and can run in separate worktrees. Write "None" if every phase depends on the one before.>
```
