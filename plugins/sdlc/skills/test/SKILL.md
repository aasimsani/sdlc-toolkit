---
name: test
description: SDLC stage 6. Proves every acceptance criterion with literal evidence, runs the fresh-context verifier subagent and a final pr-review --local, and commits docs/sdlc/<slug>/verify.md. Use when the user runs /sdlc:test or the sdlc skill routes here.
argument-hint: "<slug>"
---

# Stage 6 — Test

Read `${CLAUDE_PLUGIN_ROOT}/references/stage-rules.md` and `${CLAUDE_PLUGIN_ROOT}/references/tools.md` first.

The build session already ran its own checks. This stage adds two looks from agents that didn't write the code. The verifier runs the behavior, and pr-review reads the whole branch. It also records evidence a reviewer can read without rerunning anything.

Feature: `$ARGUMENTS`

## Steps

1. **Run the verify command** on a clean checkout of the feature branch, and keep the literal output.

2. **Dispatch the `verifier` subagent.** Pass it the paths to `spec.md` and `plan.md` and the verify command. It runs the app, exercises each acceptance criterion and reports what it saw. It never fixes anything.

3. **Check the UI if there is one.** Open it with the browser tools, take screenshots, and compare them against the spec or the mockups.

4. **Run the final `pr-review --local`** on the whole branch, and copy the report to `pr-review/test-1.md`. Compare its fingerprints with the last Build run. A Critical or High finding sends the feature back to Build.

5. **Run the agent evals if the diff changes them.** When the diff touches `CLAUDE.md`, `.claude/**` or skills, and the repo has an eval suite, run it and record the pass rate.

6. **Write `docs/sdlc/<slug>/verify.md`** from the template. Every acceptance criterion needs evidence a reader can check, such as a test name, command output or a screenshot path.

7. **Gate.** If any criterion fails, or the verifier sees behavior that doesn't match the plan, add the failures to `plan.md` as new work items and go back to `sdlc:build`. If everything passes, get approval and commit `verify.md`, the pr-review report and `sdlc.yaml` together.

## Template

~~~markdown
# <Feature title> — verification

## Verify command
`<command>`

```
<last 20 lines of literal output>
```

## Acceptance criteria
| Id | Evidence | Result |
|---|---|---|
| AC1 | `<test name>` passes, and the verifier saw <what> | pass |

## Verifier report
<The verifier subagent's report, verbatim.>

## pr-review
- Report: `pr-review/test-1.md`, with verdict <verdict> and totals <Critical n, High n, Medium n, Low n>
- Fixed since Build: <fingerprints>
- Open, with reasons: <fingerprint — reason>

## Gaps
- <anything untested, and why>
~~~
