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
| 5 | Build | code + tests | `pr-review --local` after each phase |
| 6 | Test | `verify.md` | `verifier` subagent + final `pr-review --local` |
| 7 | Ship | PR + `review.md` | `pr-review --repo --pr`, then a human approves and merges |
| 8 | ADR | `adr.src.html` + `adr.html`, a copy of the RFC updated to what shipped | `egm-drift-report` |
| 9 | Maintain | `lessons.md` | `egm-drift-report` + live signals |

`docs/sdlc/<slug>/sdlc.yaml` records each stage's status, owner and approver. A human approves every artifact. Claude never approves its own work, merges a PR, or deploys to production.

## Install

```bash
claude plugin marketplace add aasimsani/sdlc-toolkit
claude plugin install sdlc@sdlc-toolkit
```

Then run `/sdlc:setup` in a repo. It installs EGM and pr-review if they're missing. It also makes sure `CLAUDE.md` names one verify command and that `REVIEW.md` exists.

## Use

| Command | What it does |
|---|---|
| `/sdlc:sdlc` | Shows a status board of every feature in flight, with who it's waiting on. |
| `/sdlc:sdlc <idea or slug>` | Starts a feature, or runs the next stage of an existing one. |
| `/sdlc:<stage> <slug>` | Runs one stage: `intent`, `spec`, `rfc`, `plan`, `build`, `test`, `ship`, `adr` or `maintain`. |
| `… --adopt <path\|url>` | Brings in an artifact someone wrote elsewhere, such as a file, Notion page, Google Doc or Linear doc, then runs its review and gate. |
| `… --review` | Runs as the stage's manager. Claude reviews someone else's artifact and records your decision without editing it. |
| `/sdlc:maintain drift` | Checks every ADR against the current code. |

## Cost

The reviews are deliberately heavy. `egm-brainstorm` and `egm-review` start several subagents, and each pr-review run is a full `claude -p` session on Opus. The approver can skip a stage's Goldfish review for a small change, and `sdlc.yaml` records the reason.

## Develop

```bash
claude plugin validate plugins/sdlc
claude --plugin-dir plugins/sdlc      # try local edits without reinstalling
claude plugin update sdlc@sdlc-toolkit
```
