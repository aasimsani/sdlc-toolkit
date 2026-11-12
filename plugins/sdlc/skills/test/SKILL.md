---
name: test
description: SDLC stage 6. Proves every acceptance criterion with literal evidence, writes the final tests and audits the suite with the testing toolkit, runs the fresh-context verifier subagent and a final pr-review --local, and commits docs/sdlc/<slug>/verify.md. Use when the user runs /sdlc:test or the sdlc skill routes here.
argument-hint: "<slug>"
---

# Stage 6 — Test

Read `${CLAUDE_PLUGIN_ROOT}/references/stage-rules.md` first. This stage also uses `${CLAUDE_PLUGIN_ROOT}/references/pr-review.md` and `${CLAUDE_PLUGIN_ROOT}/references/testing-toolkit.md`.

The build session already ran its own checks. This stage first finishes the testing, because a green suite proves only what its tests check. It writes the tests that need the whole feature, checks the tests Build wrote, and audits the suite. Then it adds two looks from agents that didn't write the code. The verifier runs the behavior, and pr-review reads the whole branch. It also records evidence a reviewer can read without rerunning anything.

Feature: `$ARGUMENTS`

## Steps

1. **Run the final tests and check the rest.** Invoke `testing-toolkit:testing` on the whole branch, with the inputs and overrides in `testing-toolkit.md`. It writes and runs the tests the plan left for this stage, such as an end-to-end or a load test. It checks Build's tests against the plan's Tests section, finds changed code that no test checks, and writes the missing tests. Commit the tests it adds. Without the toolkit, write the final tests yourself and record why the check didn't run.

2. **Audit the tests.** Invoke `testing-toolkit:test-audit` on the test files the branch added or changed, as `testing-toolkit.md` describes. It removes or merges a test only when a stronger test covers the same contract, and it writes a ledger that says so. This is the stage's last change to the tests, so every later step sees the suite that ships.

3. **Run the verify command** on a clean checkout of the feature branch, and keep the literal output.

4. **Dispatch the `verifier` subagent.** Pass it the paths to `spec.md` and `plan.md` and the verify command. It runs the app, exercises each acceptance criterion and reports what it saw. It never fixes anything.

5. **Check the UI if there is one.** Open it with the browser tools, take screenshots, and compare them against the spec or the mockups.

6. **Run the final `pr-review --local`** on the whole branch, as `pr-review.md` describes, and compare it with the last Build run. A blocking finding sends the feature back to Build. This run also catches over-engineering that only shows across phases, such as an option no phase ended up using, so record its "Net:" line in `verify.md`.

7. **Run the agent evals if the diff changes them.** When the diff touches `CLAUDE.md`, `.claude/**` or skills, and the repo has an eval suite, run it and record the pass rate.

8. **Write `docs/sdlc/<slug>/verify.md`** from the template. Every acceptance criterion needs evidence a reader can check, such as a test name, command output or a screenshot path. When the repo has a verification skill, add or update its feature file for this feature on the same branch, so the next change to the feature is checked the same way.

9. **Gate.** If any criterion fails, a test the testing skill wrote fails on the code, or the verifier sees behavior that doesn't match the plan, add a phase to `plan.md` for the failures and go back to `sdlc:build`. If everything passes, get approval and commit `verify.md`, the testing report, the audit ledger, the pr-review report and `sdlc.yaml` together.

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

## Tests
- Report: `testing/test.md`, for the scenario <scenario>
- Done when: <the playbook's condition, and whether it holds>
- Final tests: <test names, each with its result>
- Tests added to close a gap: <test names, or none>
- Audit: `testing/audit.md`, with <n> tests removed or merged

## Verifier report
<The verifier subagent's report, verbatim.>

## pr-review
- Report: `pr-review/test-1.md`, with verdict <verdict> and totals <Critical n, High n, Medium n, Low n>
- Net: <the ponytail lens's "-N lines and -M dependencies possible", or "lean already">
- SIMPLE cuts left in, with reasons: <fingerprint — reason>
- Fixed since Build: <fingerprints>
- Open, with reasons: <fingerprint — reason>

## Gaps
- <anything untested, and why>
~~~
