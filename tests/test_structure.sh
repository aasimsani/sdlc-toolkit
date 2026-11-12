#!/usr/bin/env bash
# Run with: bash tests/test_structure.sh
# These are invariants of how the plugin's text is organised. Every file a skill
# tells Claude to read must exist, and each cross-stage rule lives in one file.
# The eval suite under evals/ is test data, so the checks skip it.
set -uo pipefail

P="$(cd "$(dirname "$0")/.." && pwd)/plugins/sdlc"
fail=0
check() { if eval "$2"; then echo "ok   - $1"; else echo "FAIL - $1"; fail=1; fi; }
files_matching() { grep -rlE --exclude-dir=evals "$1" "$P" | sed "s|$P/||" | tr '\n' ' '; }
once() { [ "$(grep -rlE --exclude-dir=evals "$1" "$P" | wc -l | tr -d ' ')" = 1 ]; }

missing="$(grep -rhoE --exclude-dir=evals '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$P" | sed 's|^\${CLAUDE_PLUGIN_ROOT}/||; s|\.$||' \
  | sort -u | while read -r f; do [ -e "$P/$f" ] || printf '%s ' "$f"; done)"
check "every plugin file a skill points at exists (missing: ${missing:-none})" '[ -z "$missing" ]'

# A bare `name.md` in backticks under references/ must exist too.
# The leading "(" on the case pattern keeps bash 3.2 from misreading it inside $( ).
stale_refs() {
  grep -rhoE --exclude-dir=evals '`[a-z-]+\.md`' "$P" | tr -d '`' | sort -u | while read -r f; do
    case "$f" in (intent.md|spec.md|plan.md|verify.md|review.md|lessons.md|rfc.md|adr.md|panel.md|ponytail-lens.md) continue ;; esac
    [ -e "$P/references/$f" ] || printf '%s ' "$f"
  done
}
stale="$(stale_refs)"
check "every reference file named in passing exists (stale: ${stale:-none})" '[ -z "$stale" ]'

mistake_rule='mistake[a-z ]* twice|propose a (line|one-line addition)'
check "the repeated-mistake rule is stated in one file ($(files_matching "$mistake_rule"))" 'once "$mistake_rule"'
check "blocking findings are defined in one file ($(files_matching 'Critical (and|or) High'))" \
  'once "Critical (and|or) High"'
check "the ponytail precedence rule is stated in one file ($(files_matching 'never overrides the loop|win over (it|ponytail)'))" \
  'once "never overrides the loop|win over (it|ponytail)"'

exit "$fail"
