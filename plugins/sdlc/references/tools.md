# External tools the stages use

The loop leans on four tools that live outside this plugin. They're EGM (Google's Elephant-Goldfish Model), pr-review, ponytail and the `rfc` skill. `sdlc:setup` installs the first three.

## Find a plugin's install path

```bash
claude plugin list --json | jq -r '.[] | select(.enabled and (.id | startswith("egm@"))) | .installPath'
```

Swap `egm@` for `pr-review@` to find pr-review. If the command prints nothing, the plugin isn't installed or isn't enabled. Tell the user to run `sdlc:setup`. Never guess a path.

## Run an EGM skill

EGM's skills set `disable-model-invocation`, so the Skill tool refuses them. EGM's own Claude Code guide says to read the skill's `SKILL.md` and follow it in the same thread. To run `egm-<name>`, take these steps:

1. Find `EGM_ROOT` with the command above.
2. Read `$EGM_ROOT/docs/claude.md`, then `$EGM_ROOT/skills/egm-<name>/SKILL.md`.
3. Follow that skill in this thread. When it names `${CLAUDE_PLUGIN_ROOT}` or a plugin-relative path such as `agents/`, `resources/` or `docs/`, read it under `EGM_ROOT`. Dispatch each Goldfish as the named subagent `egm:egm-<persona>`, such as `egm:egm-zoom-out`.
4. Treat `docs/sdlc/<slug>/egm/` as the EGM artifact directory. Every brief, draft and report EGM writes goes there and is committed with the stage.
5. Pass the inputs from the table below up front, so EGM doesn't stop to ask for them.
6. Follow EGM's interaction rules while its skill runs. They allow one question per turn, with no "Recommended" labels. Return to the stage when the EGM skill reaches its terminal gate.

The **Goldfish context** for a feature is `CLAUDE.md`, the earlier approved artifacts in `docs/sdlc/<slug>/`, and the `README.md` of each directory the change touches.

| Stage | EGM skill | Inputs |
|---|---|---|
| Setup | `egm-bootstrap` | `path`: the repo root, or the subtree the team owns |
| Intent | `egm-brainstorm` | The originator's description of the problem |
| Intent, adopt or review mode | `egm-review-loop` | `TargetFile: intent.md`, `SemanticTarget: full file`, `Reviewers: [egm-comprehension, egm-zoom-out]`, `Standards: {egm-comprehension: heilmeier-standard, egm-zoom-out: zoom-out-standard}`, the Goldfish context |
| Spec | `egm-review-loop` | `TargetFile: spec.md`, `SemanticTarget: full file`, `Reviewers: [egm-comprehension, egm-zoom-out]`, `Standards: {egm-comprehension: feature-spec-standard, egm-zoom-out: zoom-out-standard}`, the Goldfish context |
| RFC | `egm-draft`, only when the `rfc` skill isn't available | The concepts brief, `intent.md` and `spec.md` |
| RFC | `egm-review` | `TargetFile`: the RFC source, `Step: feature_spec`, the Goldfish context. Its Stage 7 runs `egm-resolve` on the findings. |
| Plan | `egm-review` | `TargetFile: plan.md`, `Step: implementation`, the Goldfish context plus the RFC |
| ADR | `egm-drift-report` | The RFC, to list where the code diverged from it |
| Maintain | `egm-drift-report` | `docs/sdlc/`, to check every ADR against the current code |
| Any review mode | `egm-resolve` | The report's findings, worked through with the artifact's owner |

## Run pr-review

Find `PR_REVIEW_ROOT` with the command above. The script is `$PR_REVIEW_ROOT/skills/pr-review/pr-review.sh`. Every run takes several minutes and costs real money, so run it in the background and record the cost line from the report.

- **Local** (Build and Test). Commit first, because the script reviews committed `HEAD` only. Then run `"$SCRIPT" --local` from the repo root. It prints the review file's path on stdout.
- **PR** (Ship). Run `"$SCRIPT" --repo <owner/name> --pr <n>`. It writes `~/pr-reviews/<date>/<owner>_<repo>_PR<n>.md`.

### Perspectives

pr-review takes one `--panel FILE` and any number of `--lens FILE` flags. The panel says who reviews, and each lens adds a reviewer or rules. Build every run's flags in this order:

1. **The stage's default lens.** Build and Test runs add `--lens "$PR_REVIEW_ROOT/examples/ponytail-lens.md"`. It adds an over-engineering reviewer whose SIMPLE findings are never High or Critical, so it suggests cuts without blocking the stage. Ship adds no default lens, so the human reviewer sees correctness findings without simplification nits.
2. **The feature's perspectives.** When `sdlc.yaml` has a `pr_review` block, pass its panel and lenses to every run. A stage key overrides the feature default for that stage.

   ```yaml
   pr_review:
     panel: .pr-review/panels/red-team.md        # optional, for every stage
     lenses: [.pr-review/lenses/migrations.md]   # added to every stage
     ship: {panel: .pr-review/panels/default-plus-lead.md}
   ```

3. **The repo's own perspectives.** pr-review reads `REVIEW.md`, `.pr-review/panel.md` and `.pr-review/lenses/*.md` from the base branch by itself, so don't pass them.

When the spec is high-risk, ask the approver at Build whether to add a specialist panel or lens for the risky area, such as the red-team panel in `$PR_REVIEW_ROOT/examples/` for an auth change. Record the answer in `sdlc.yaml`.

After each run, take these steps:

1. Copy the review to `docs/sdlc/<slug>/pr-review/<stage>-<n>.md`, numbering runs from 1.
2. Read its `## Summary` totals and `## Issues` table.
3. Compare its fingerprints with the previous run's. A fingerprint that disappeared is **fixed**, one that appeared is **new**, and one in both runs is **open**.
4. Critical and High findings block the stage. Fix each one, or record a won't-fix reason that the approver accepts. Medium and Low findings are the owner's call.

The script appends the repo's `REVIEW.md` to its prompt, so the team's review rules apply on every run.

## Run ponytail

[ponytail](https://github.com/DietrichGebert/ponytail) pushes code toward the smallest change that works. Its skills accept model invocation, so call them with the Skill tool.

| Stage | How ponytail runs |
|---|---|
| Plan | The plan's self-challenge applies ponytail's ladder to every file and function the plan adds. |
| Build | Invoke `ponytail:ponytail` before the first phase. It stays on for the rest of the session. |
| Build, Test | pr-review runs with `examples/ponytail-lens.md`, which checks the code ponytail shaped. |
| Maintain | `drift` also runs `ponytail:ponytail-audit` on the whole repo. |

The ladder asks five questions in order. Does it need to exist at all? Does this codebase already have it? Does the standard library or the platform do it? Does an installed dependency solve it? Can it be one line? The first "yes" names the smaller option.

Ponytail never overrides the loop's own rules. Every test in `plan.md` gets written, even where ponytail's "one runnable check" minimum would stop sooner, because those tests prove the acceptance criteria. Every requirement in `spec.md` gets built, including its non-functional requirements, because the approver already decided they're needed. When ponytail and the plan disagree, follow the plan and raise the disagreement with the engineer.

If ponytail isn't installed, the lens still runs through pr-review. Say that the Build session ran without ponytail mode.

## Run the rfc skill

`rfc` is a personal skill, not part of this plugin. When the session lists it, invoke it with the Skill tool and give it these overrides:

- Write the source to `docs/sdlc/<slug>/rfc.src.html` and build `rfc.html` next to it. Its default location is the repo root.
- In its Gather step, read the concepts brief, `intent.md` and `spec.md` first.

When the skill isn't available, run `egm-draft` to write `docs/sdlc/<slug>/rfc.md`. Then add any of these RFC sections the draft lacks: Constraints, an Options table with a verdict column, a Fallback with its triggers, Phases with a PR table, Proposed tickets, and Blast radius.
