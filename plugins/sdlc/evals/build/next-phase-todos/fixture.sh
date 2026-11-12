#!/usr/bin/env bash
# Seeds the empty workspace for this case. `claude plugin eval --scaffold` runs it.
set -euo pipefail
git init -q -b main .
git config user.email dev@example.com
git config user.name Dev
mkdir -p docs/sdlc docs/notes
cat > CLAUDE.md <<'EOF'
# Reports service
Internal service that builds reports for the support and finance teams.

## Commands
- Verify: `sh verify.sh`. Healthy output ends with `N passed, 0 failed`.

## Things Claude gets wrong
EOF
cat > REVIEW.md <<'EOF'
# Review rules
A finding must name a behaviour that breaks. Style taste never counts.
EOF
printf 'echo "3 passed, 0 failed"\n' > verify.sh
echo "Each subfolder holds one feature's artifacts and its sdlc.yaml." > docs/sdlc/README.md
mkdir -p docs/sdlc/bulk-export export tests
cat > docs/sdlc/bulk-export/intent.md <<'EOF'
# Bulk export

## Problem
Support agents export customer records one page at a time. A 10,000-row export takes about 40 minutes of clicking.

## Proposed outcome
An agent starts one export and gets a single CSV file by email.

## Success criteria
- An export of 10,000 rows finishes in under 60 seconds.

## Affected users and systems
- Support agents, the admin app, the reports service

## Constraints
- No new infrastructure

## Out of scope
- Scheduled exports

## Open questions
- None
EOF
cat > docs/sdlc/bulk-export/spec.md <<'EOF'
# Bulk export — spec

Risk: low
Policies applied: none

## Summary
One export job per request, delivered as a single CSV file by email.

## Requirements
- **R1** An agent can export every customer record that matches the current filter.
- **R2** The export is one CSV file with a header row.
- **R3** The agent gets an email with a link when the file is ready.

## Acceptance criteria
| Id | Criterion | Covers |
|---|---|---|
| AC1 | The query reads rows in pages of 1,000 | R1 |
| AC2 | An export of 10,000 rows produces one file with 10,001 lines | R2 |
| AC3 | The agent's inbox gets one email with a working link | R3 |
EOF
cat > docs/sdlc/bulk-export/plan.md <<'EOF'
# Bulk export — plan

Verify command: `sh verify.sh`

## Files to change
| File | Change |
|---|---|
| `export/query.sh` | Read rows in pages of 1,000 |
| `export/csv.sh` | Write every page to one CSV file |
| `export/mail.sh` | Email a link to the finished file |

## Phases
| # | Phase | Covers | Depends on | First failing test | Runs in | Status |
|---|---|---|---|---|---|---|
| 1 | Paged query | AC1 | — | `tests/query_test.sh::pages_of_1000` | main session | done |
| 2 | CSV writer | AC2 | 1 | `tests/csv_test.sh::one_file` | main session | pending |
| 3 | Email delivery | AC3 | 2 | `tests/mail_test.sh::sends_link` | main session | pending |

Status is `pending`, `in_progress` or `done`. One phase is in progress per session or worktree.

### Phase 1 — Paged query
Read rows in pages of 1,000 so memory stays flat.

### Phase 2 — CSV writer
Write every page to one CSV file with a header row.

### Phase 3 — Email delivery
Email the agent a link to the finished file.

## Todos
Only a phase that's in progress has todos here. Build writes the next phase's todos when it starts that phase.

### Phase 1 — Paged query
- [x] Write the failing test `pages_of_1000` and watch it fail
- [x] Implement paging until the test passes
- [x] Refactor, run the verify command, and run pr-review

## Tests
| Acceptance criterion | Test |
|---|---|
| AC1 | `tests/query_test.sh::pages_of_1000` |
| AC2 | `tests/csv_test.sh::one_file` |
| AC3 | `tests/mail_test.sh::sends_link` |
EOF
cat > docs/sdlc/bulk-export/sdlc.yaml <<'EOF'
feature: bulk-export
branch: dana/bulk-export
stages:
  intent: {status: approved, owner: Dana, approver: Lee, approved_by: Lee, date: 2026-10-01, artifact: intent.md}
  spec:   {status: approved, owner: Dana, approver: Lee, approved_by: Lee, date: 2026-10-03, artifact: spec.md}
  rfc:    {status: skipped, reason: "small change, skipped by Lee"}
  plan:   {status: approved, owner: Dana, approver: Lee, approved_by: Lee, date: 2026-10-06, artifact: plan.md}
  build:  {status: draft, owner: Dana}
EOF
echo '# reads rows in pages of 1,000' > export/query.sh
echo '# pages_of_1000' > tests/query_test.sh
git add -A && git commit -q -m "base"
git switch -q -c dana/bulk-export
