---
name: build
description: SDLC stage 5. Implements an approved docs/sdlc/<slug>/plan.md phase by phase in ponytail mode, test first, with a verify loop and a pr-review --local run at the end of each phase. Use when the user runs /sdlc:build or the sdlc skill routes here.
argument-hint: "<slug> [phase]"
---

# Stage 5 — Build

Read `${CLAUDE_PLUGIN_ROOT}/references/stage-rules.md` and `${CLAUDE_PLUGIN_ROOT}/references/tools.md` first.

The engineer already approved the plan, so Claude works through it without asking about each edit. A session checks and fixes its own work before anyone else sees it. Because pr-review reads the code without this session's context, it catches what the session talked itself into.

Feature: `$ARGUMENTS`

## Before you start

- Stop if `plan.md` isn't approved.
- Work on the feature branch from `sdlc.yaml`, never on the default branch.
- Run the verify command once, so you know the starting state.
- **Turn on ponytail mode.** Invoke `ponytail:ponytail` with the Skill tool, at its default level, before the first phase. It shapes every edit toward the smallest change that works. The plan's tests and the spec's requirements still win over it, as `tools.md` explains. If ponytail isn't installed, say so and continue.

## Each phase

1. **Pick the phase.** Take the first one with unchecked items whose dependencies are done, or the phase the user named.

2. **Test first.** Write the failing test, run it, and confirm it fails for the expected reason. Commit the test.

3. **Make it pass.** Write the smallest change that makes the test pass, and don't edit the test to make it pass. If the test itself is wrong, stop and tell the user.

4. **Refactor and verify.** Run the verify command and paste the last lines of its output. A phase isn't done until the verify command passes.

5. **Review with pr-review.** Commit, then run `pr-review --local` with the ponytail lens and the feature's perspectives, as `tools.md` describes. Copy the report to `pr-review/build-<n>.md`. Apply the SIMPLE cuts the owner agrees with now, while the code is cheap to change. Fix every Critical and High finding, commit the fixes, and run it again. Repeat until those findings are fixed or carry a won't-fix reason that the approver accepts. Use the fingerprint comparison to report what's fixed, new and still open.

6. **Keep `plan.md` true.** Check off each item when it's done. When the work has to depart from the plan, update `plan.md` in the same commit as the code and say what changed. If the departure changes a requirement or the RFC's design, stop and go back to that stage.

## Parallel phases

When the plan's "Parallel work" names phases that share no files, offer to run them in separate worktrees. Use `claude --worktree <name>` in another terminal, or Agent with `isolation: "worktree"`. Start with two or three at a time. Each worktree runs its own verify loop and its own `pr-review --local`, and is merged back only after both pass.

## Finish

Build is done when every item in `plan.md` is checked, the verify command passes, and the last pr-review shows no open Critical or High findings. Set the stage to approved in `sdlc.yaml`, commit, and hand off to `sdlc:test`.

When the same mistake comes up twice, propose a line for "Things Claude gets wrong" in `CLAUDE.md`.
