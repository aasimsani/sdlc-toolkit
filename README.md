# sdlc-toolkit

A Claude Code plugin that runs a feature through the loop in Anthropic's [AI-Native SDLC Playbook](https://claude.com/resources/articles/the-ai-native-sdlc-playbook). Each stage ends by committing one artifact under `docs/sdlc/<slug>/` in the target repo, and that commit starts the next stage. Agents with fresh context review every artifact: [EGM](https://github.com/google/elephant-goldfish-model) Goldfish reviewers check the documents, and [pr-review](https://github.com/aasimsani/pr-review) checks the code.

```
intent → spec → RFC → plan → build → test → ship → ADR → maintain
  ↑                                                         │
  └────────── follow-ups and incidents become new intents ──┘
```

| # | Stage | Artifact | Fresh-context review |
|---|---|---|---|
| 1 | Intent | `intent.md` | `egm-brainstorm` (seven Goldfish lenses) |
| 2 | Spec | `spec.md` | `egm-review-loop` with the feature-spec standard |
| 3 | RFC | `rfc.src.html` + `rfc.html` from the `rfc` skill, or `rfc.md` from `egm-draft` | `egm-review`, then `egm-resolve` |
| 4 | Plan | `plan.md` | `egm-review` implementation-readiness stage |
| 5 | Build | code + tests | Ponytail mode while coding, then `pr-review --local` with the ponytail lens after each phase |
| 6 | Test | `verify.md` | `verifier` subagent + final `pr-review --local` with the ponytail lens |
| 7 | Ship | PR + `review.md` | `pr-review --repo --pr`, then a human approves and merges |
| 8 | ADR | `adr.src.html` + `adr.html`, a copy of the RFC updated to what shipped | `egm-drift-report` |
| 9 | Maintain | `lessons.md` | `egm-drift-report`, `ponytail-audit` + live signals |

`docs/sdlc/<slug>/sdlc.yaml` records each stage's status, owner and approver. A human approves every artifact. Claude never approves its own work, merges a PR, or deploys to production.

## Install

```bash
claude plugin marketplace add aasimsani/sdlc-toolkit
claude plugin install sdlc@sdlc-toolkit
```

Then run `/sdlc:setup` in a repo. It installs EGM, pr-review and [ponytail](https://github.com/DietrichGebert/ponytail) if they're missing. It also makes sure `CLAUDE.md` names one verify command and that `REVIEW.md` exists.

## Use

| Command | What it does |
|---|---|
| `/sdlc:sdlc` | Shows a status board of every feature in flight, with who it's waiting on. |
| `/sdlc:sdlc <idea or slug>` | Starts a feature, or runs the next stage of an existing one. |
| `/sdlc:<stage> <slug>` | Runs one stage: `intent`, `spec`, `rfc`, `plan`, `build`, `test`, `ship`, `adr` or `maintain`. |
| `… --adopt <path\|url>` | Brings in an artifact someone wrote elsewhere, such as a file, Notion page, Google Doc or Linear doc, then runs its review and gate. |
| `… --review` | Runs as the stage's manager. Claude reviews someone else's artifact and records your decision without editing it. |
| `/sdlc:maintain drift` | Checks every ADR against the current code, and audits the repo for over-engineering with `ponytail-audit`. |

## Extending

Most extensions are a markdown file in the target repo or one line in `sdlc.yaml`. Plugin edits are needed only to change what a stage does.

### Code-review perspectives (pr-review)

pr-review gives each review one **panel**, which says who reviews, and any number of **lenses**, which add a reviewer or rules. The [pr-review README](https://github.com/aasimsani/pr-review#extending-perspectives) covers the files themselves. The loop picks them up from three places:

| Where | Applies to | Example |
|---|---|---|
| The stage default in [`references/tools.md`](plugins/sdlc/references/tools.md) | Every feature | Build and Test add the ponytail lens. Ship adds none. |
| The `pr_review` block in a feature's `sdlc.yaml` | One feature, with optional per-stage overrides | A red-team panel for an auth change |
| `REVIEW.md` and `.pr-review/` in the target repo | Every review of that repo | A migrations lens for a repo with a database |

The ponytail lens runs during Build and Test because cutting code is cheapest before review. Its SIMPLE findings are never High or Critical, so they suggest cuts without blocking a stage. It stays off the Ship review, so the human approver reads correctness findings without simplification nits. To change that, edit the stage defaults in `tools.md`, or set `ship: {lenses: [...]}` for one feature.

### Ponytail

Ponytail runs at four points without anyone invoking it. Plan applies its ladder to every file, dependency and option the plan adds. Build turns on ponytail mode before the first phase. Build and Test pass its lens to pr-review. `/sdlc:maintain drift` runs `ponytail-audit`. The plan's tests and the spec's requirements always win over ponytail. To change where it runs, edit the Run ponytail table in [`references/tools.md`](plugins/sdlc/references/tools.md).

### Document reviewers (EGM)

The table in [`references/tools.md`](plugins/sdlc/references/tools.md) says which EGM skill, reviewers and standards each stage uses.

- **Swap or add a reviewer.** Change a stage's `Reviewers` list. EGM ships `egm-design`, `egm-codebase-details`, `egm-comprehension`, `egm-implementation-readiness`, `egm-structural`, `egm-style`, `egm-zoom-out` and `egm-inventive-catalyst`.
- **Add a standard.** `egm-review-loop` takes a standard's short name or a path. Write a team standard as a markdown file, for example `docs/sdlc/standards/api-standard.md`, and map a reviewer to its path in the stage's `Standards`.
- **Skip a review for one feature.** The approver records `goldfish: skipped` with a reason in `sdlc.yaml`.

### Policies

The Spec stage applies every policy skill in the session, such as security, compliance, brand or API rules. To add a policy, write it as a skill in the target repo's `.claude/skills/` or in a plugin. The next spec picks it up, and `spec.md` lists it under Policies applied. Because a skill only advises, also add the rule to `REVIEW.md` so pr-review checks the code against it.

### Stages and templates

- **Change an artifact's shape.** Edit the template at the bottom of the stage's `SKILL.md`.
- **Add a stage.** Add `plugins/sdlc/skills/<stage>/SKILL.md` that reads `references/stage-rules.md` and ends with its gate. Then add a row to the stage table in `skills/sdlc/SKILL.md`, which the router reads in order.
- **Swap a tool.** Each stage names its tools in `references/tools.md`. For example, the RFC stage uses the `rfc` skill when it's installed, and `egm-draft` when it isn't.

After editing the plugin, bump `version` in `plugins/sdlc/.claude-plugin/plugin.json` and run `claude plugin update sdlc@sdlc-toolkit`.

## Cost

The reviews are deliberately heavy. `egm-brainstorm` and `egm-review` start several subagents, and each pr-review run is a full `claude -p` session on Opus. The approver can skip a stage's Goldfish review for a small change, and `sdlc.yaml` records the reason.

## Develop

```bash
claude plugin validate plugins/sdlc
claude --plugin-dir plugins/sdlc      # try local edits without reinstalling
claude plugin update sdlc@sdlc-toolkit
```
