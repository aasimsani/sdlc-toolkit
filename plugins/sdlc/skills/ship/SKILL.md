---
name: ship
description: SDLC stage 7. Opens the PR, runs pr-review on it, fixes Critical and High findings, records them in docs/sdlc/<slug>/review.md, and prepares the deploy up to the human production gate. Use when the user runs /sdlc:ship or the sdlc skill routes here.
argument-hint: "<slug>"
---

# Stage 7 — Ship

Read `${CLAUDE_PLUGIN_ROOT}/references/stage-rules.md` and `${CLAUDE_PLUGIN_ROOT}/references/tools.md` first.

The agent that wrote the code has no way to approve it, so the duties stay separate. Claude may act up to the production gate but can't pass it.

Feature: `$ARGUMENTS`

## Steps

1. **Open the PR.** Stop if `verify.md` isn't approved. Push the branch and open the PR with the repo's PR conventions. The PR body links every artifact in `docs/sdlc/<slug>/`, so the reviewer can read the reasoning without asking.

2. **Run pr-review on the PR** with `--repo <owner/name> --pr <n>`, as `tools.md` describes. Copy the report to `pr-review/ship-<n>.md`. This run reviews the head that was actually pushed, including any merge from the base branch.

3. **Fix the Critical and High findings.** Fix each one, rerun the verify command, push, and rerun pr-review until those findings are fixed or carry an accepted won't-fix reason.

4. **Write `docs/sdlc/<slug>/review.md`** from the template.

5. **Hand the PR to a human.** Claude never approves or merges the PR. Tell the user it's ready, and name who must approve it under branch protection. Merge only when the user explicitly says to.

6. **Prepare the deploy.** Write the deploy and rollback steps into `review.md`. Claude may deploy to dev or staging if the repo allows it. A production deploy needs a named person's authorization, so Claude prepares it and that person runs or approves it.

7. **Gate.** Once the PR is merged, record the merging human as `approved_by` and commit `review.md`, the reports and `sdlc.yaml`.

When a finding repeats one from an earlier feature, propose a line for "Things Claude gets wrong" in `CLAUDE.md`.

## Template

```markdown
# <Feature title> — review

PR: <url>
Approved and merged by: <human>

## Findings
| Fingerprint | Severity | Finding | Disposition |
|---|---|---|---|
| `SEC\|path\|symbol\|summary` | High | <what breaks> | fixed in <sha> |
| `PERF\|path\|symbol\|summary` | Low | <...> | won't fix — <reason> |

## Deploy
1. <step>

## Rollback
1. <step>
```
