# Rules every stage follows

## The feature folder

Each feature lives in `docs/sdlc/<slug>/` in the target repo. The folder holds the artifacts, the reports reviewers wrote about them, and one state file, `sdlc.yaml`.

```yaml
feature: bulk-export
ticket: ENG-1234            # Linear/Jira/GitHub id, if the work started from one
branch: aasim/eng-1234-bulk-export
stages:
  intent:   {status: approved, owner: Aasim, approver: Aasim, approved_by: Aasim, date: 2026-11-11, artifact: intent.md}
  spec:     {status: draft,    owner: Priya, approver: Aasim, artifact: spec.md}
  rfc:      {status: skipped,  reason: "one-file change, approved by Aasim"}
```

- `status` is `draft`, `approved` or `skipped`. A stage is done when it's `approved` or `skipped`.
- `owner` is the person who produces the artifact. `approver` is the person who must approve it. Ask for both at the start of a stage if they're unknown. Never invent a name. Write `unassigned` instead.
- `artifact` is a path in the folder, or a URL when the artifact lives elsewhere, such as a Notion page.
- `goldfish: skipped` with a `reason` records that the approver skipped the stage's Goldfish review.

## Three modes

Every stage runs in one of three modes. The arguments pick the mode, and author is the default.

| Mode | When | What Claude does |
|---|---|---|
| `author` | Claude produces the artifact with the owner. | Run the stage's steps, then the gate. |
| `adopt <path\|url>` | The owner, or a teammate, already wrote it somewhere else. | Fetch the source with the right tool (Read, a Notion, Google Drive or Linear MCP, or `gh`). Put it into the stage's template without changing its decisions. List every template section the source leaves empty as an open question. Record the source as `source:` in `sdlc.yaml`, then run the gate. |
| `review` | You're managing the stage, and someone else owns the artifact. | Don't edit the artifact. Run the stage's Goldfish review and give the findings to the approver. Record the approver's decision, approve or request changes, in `sdlc.yaml`. When the artifact sits on a teammate's branch, read it with `git show origin/<branch>:<path>`, and commit to that branch only if the approver says to. |

## The gate

Every stage ends with the same gate.

1. **Run the Goldfish review** the stage names, unless the approver skips it for a small change. Fix what the owner agrees to fix.
2. **Ask the approver** to approve the artifact or request changes. Revise until they approve. Claude never approves its own work.
3. **Update `sdlc.yaml`** with `status: approved`, `approved_by` and `date`.
4. **Commit the stage on its own.** One commit holds the artifact, its review reports and `sdlc.yaml`. Follow the repo's commit conventions. When it has none, use `docs(sdlc): <stage> for <slug>`.

## Branches and history

- Never commit on the default branch. Before the first commit for a feature, create a feature branch with the repo's branch-naming convention, and record it in `sdlc.yaml`.
- Earlier artifacts don't change silently. When a later stage finds that an earlier artifact is wrong, show the conflict. If the approver agrees, fix the earlier artifact in its own commit and set that stage back to `draft` until it's re-approved.
- When Claude makes the same mistake twice in any stage, propose a one-line addition to the "Things Claude gets wrong" section of `CLAUDE.md`.

## Skipping stages

The approver may skip a stage when it adds nothing. For example, a one-file fix rarely needs an RFC. Record the reason. When the RFC is skipped, the ADR is skipped too. Build, Test and Ship are never skipped.
