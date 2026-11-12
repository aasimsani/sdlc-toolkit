#!/usr/bin/env bash
# Seeds the empty workspace for this case. `claude plugin eval --scaffold` runs it.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib/lifecycle.sh"
seed test ship
# tools/gh stands in for the GitHub CLI and records each call instead of making it. Nothing can be pushed from the
# eval sandbox, so the case's environment note says that `tools/gh pr create` publishes the branch.
git remote add origin https://github.com/example/reports.git
mkdir -p tools
cat > tools/gh <<'EOF'
#!/bin/sh
# Stand-in for the GitHub CLI. It logs each call, with the text of any body file, and answers the calls a PR needs.
log="$(cd "$(dirname "$0")/.." && pwd)/.gh-calls.log"
echo "gh $*" >> "$log"
prev=""
for a in "$@"; do
  case "$prev" in --body-file|-F) cat "$a" >> "$log" 2>/dev/null ;; esac
  prev="$a"
done
case "${1:-} ${2:-}" in
  "pr create") echo "https://github.com/example/reports/pull/42" ;;
  "pr view"|"pr list"|"pr status") echo "#42  CSV export for the invoice list  sam/csv-export  OPEN" ;;
  "repo view") echo "example/reports" ;;
esac
EOF
chmod +x tools/gh
echo ".gh-calls.log" >> .git/info/exclude
git add -A && git commit -q -m "chore: add the gh wrapper"
