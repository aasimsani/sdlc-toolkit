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
mkdir -p docs/sdlc/bulk-export
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
cat > docs/sdlc/bulk-export/sdlc.yaml <<'EOF'
feature: bulk-export
branch: dana/bulk-export
stages:
  intent: {status: draft, owner: Dana, approver: Lee, artifact: intent.md}
EOF
git add -A && git commit -q -m "base"
git switch -q -c dana/bulk-export
