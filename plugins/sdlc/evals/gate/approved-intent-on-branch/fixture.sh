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
cat > docs/notes/csv-export.md <<'EOF'
# CSV export button

Problem: Finance copies the invoice table into a spreadsheet by hand every Monday. It takes about 20 minutes, and rows get missed.

Outcome: The invoice table has an "Export CSV" button that downloads the rows currently shown.

Success: Finance stops copying by hand. An export of 2,000 rows downloads in under 5 seconds.

Who: the finance team, the invoices page.

Constraints: no new dependencies.

Out of scope: scheduled exports, Excel format.
EOF
git add -A && git commit -q -m "base"
