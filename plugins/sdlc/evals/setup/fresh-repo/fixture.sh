#!/usr/bin/env bash
# Seeds the empty workspace for this case. `claude plugin eval --scaffold` runs it.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib/lifecycle.sh"
base
# This is a repo before setup. CLAUDE.md has a team convention and no verify command, and REVIEW.md is missing.
git rm -q REVIEW.md
cat > CLAUDE.md <<'EOF'
# Reports service
Shell tools that the support and finance teams run to list invoices.

## Conventions
- Amounts are decimal strings. Never parse them as floats.
EOF
git add -A && git commit -q -m "chore: repo before sdlc setup"
