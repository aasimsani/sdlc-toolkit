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

# The tools table in stage-rules.md and the gate hook's own list must agree, because the hook is copied into
# repos and can't read the plugin's files.
tools_differ() {
  local s row
  for s in intent spec rfc plan build test ship adr maintain; do
    row="$(grep -iE "^\| *$s *\|" "$P/references/stage-rules.md" | head -1 | cut -d'|' -f3 | tr -d '` ' | tr ',' ' ')"
    [ "$row" = none ] && row=""
    [ "$(echo $row)" = "$(bash "$P/scripts/sdlc-gate.sh" tools "$s" </dev/null)" ] || printf '%s ' "$s"
  done
}
differ="$(tools_differ)"
check "the tools table matches the gate hook (differ: ${differ:-none})" \
  '[ -z "$differ" ] && [ -n "$(bash "$P/scripts/sdlc-gate.sh" tools build </dev/null)" ]'
# The ledger maps each tool to the file it leaves, so each tool the hook requires needs a line that names that file.
undefined_tools() {
  local s t
  for s in intent spec rfc plan build test ship adr maintain; do
    for t in $(bash "$P/scripts/sdlc-gate.sh" tools "$s" </dev/null); do
      grep -q "^- \`$t\` is " "$P/references/stage-rules.md" || echo "$t"
    done
  done | sort -u | tr '\n' ' '
}
undefined="$(undefined_tools)"
check "every tool the gate hook requires has its file defined (undefined: ${undefined:-none})" '[ -z "$undefined" ]'
# The gate hook's own message repeats the format, so this counts the markdown files only.
ledger_files="$(grep -rlE --exclude-dir=evals --include='*.md' 'skipped: <reason>' "$P" | sed "s|$P/||" | tr '\n' ' ')"
check "the tool ledger's format is stated in one file ($ledger_files)" '[ "$(echo $ledger_files | wc -w | tr -d " ")" = 1 ]'

# proof.md names the proof page's sections and proof-template.html builds them, so the two lists must agree.
page_sections() { grep -oE '^\| `#[a-z-]+`' "$P/references/proof.md" 2>/dev/null | tr -d '|`# ' | sort | tr '\n' ' '; }
template_sections() { grep -oE '<section id="[a-z-]+"' "$P/references/proof-template.html" 2>/dev/null | sed 's/.*id="//; s/"//' | sort | tr '\n' ' '; }
check "the proof template has the sections proof.md names ($(page_sections))" '[ -n "$(page_sections)" ] && [ "$(page_sections)" = "$(template_sections)" ]'
# The Test stage asks about a demo, and the demo skill is what a yes runs, so the stage must name the skill and the skill must exist.
check "the test stage hands a wanted demo to the demo skill" 'grep -q "sdlc:demo" "$P/skills/test/SKILL.md" && [ -f "$P/skills/demo/SKILL.md" ]'

# The stages call other plugins. plugins/sdlc-stack declares them, and Claude Code installs and tracks them from there.
STACK="$(cd "$(dirname "$0")/.." && pwd)/plugins/sdlc-stack/.claude-plugin/plugin.json"
# sdlc itself declares none, because a plugin with a missing dependency doesn't load, and then sdlc:setup can't run.
check "the sdlc plugin loads without its dependencies" '[ "$(jq ".dependencies // [] | length" "$P/.claude-plugin/plugin.json")" = 0 ]'
unlisted="$(jq -r '.dependencies[] | objects | "\(.name)@\(.marketplace)"' "$STACK" | while read -r id; do grep -qF "\`$id\`" "$P/skills/setup/SKILL.md" || printf '%s ' "$id"; done)"
check "setup lists every plugin the stack depends on (unlisted: ${unlisted:-none})" '[ -n "$(jq -r ".dependencies[]" "$STACK")" ] && [ -z "$unlisted" ]'
# A name prefix matched two pr-review plugins from different marketplaces, so a lookup names the full id.
check "every plugin lookup names a full id ($(files_matching 'startswith\("[a-z-]+@"'))" '[ -z "$(files_matching "startswith\(\"[a-z-]+@\"")" ]'

# The integration suite measures the stages with the toolkits beside them. A case that loads fewer plugins would measure sdlc alone.
INT="$(cd "$(dirname "$0")/.." && pwd)/evals-integration"
partial="$(for c in "$INT"/*/*/case.yaml; do for pl in plugins/sdlc .toolkits/testing-toolkit .toolkits/fv-toolkit; do grep -q "$pl" "$c" || echo "${c#"$INT"/}"; done; done | sort -u | tr '\n' ' ')"
check "every integration case loads sdlc and both toolkits (partial: ${partial:-none})" '[ -n "$(ls "$INT"/*/*/case.yaml 2>/dev/null)" ] && [ -z "$partial" ]'

exit "$fail"
