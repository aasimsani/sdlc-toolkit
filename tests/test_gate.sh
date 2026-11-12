#!/usr/bin/env bash
# Run with: bash tests/test_gate.sh
# The test feeds the gate hook the JSON Claude Code sends a PreToolUse hook and
# reads back its decision. It builds throwaway repos, so it touches nothing real.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="${ROOT}/plugins/sdlc/scripts/sdlc-gate.sh"
T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$T"' EXIT
fail=0

# decision <cwd> <command> prints allow, ask or deny.
decision() {
  local out
  out="$(jq -n --arg cwd "$1" --arg c "$2" \
    '{hook_event_name:"PreToolUse",tool_name:"Bash",cwd:$cwd,tool_input:{command:$c}}' \
    | bash "$GATE" 2>/dev/null)" || { echo "exit-$?"; return; }
  [ -z "$out" ] && { echo allow; return; }
  jq -r '.hookSpecificOutput.permissionDecision' <<<"$out"
}
check() {                             # args: name expected cwd command
  local got; got="$(decision "$3" "$4")"
  if [ "$got" = "$2" ]; then echo "ok   - $1"; else echo "FAIL - $1 (expected $2, got $got)"; fail=1; fi
}
mkrepo() {                            # args: dir default-branch; makes a clone whose origin/HEAD is set
  git init -q -b "$2" "$1.seed"
  git -C "$1.seed" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m base
  git clone -q --bare "$1.seed" "$1.git"
  git clone -q "$1.git" "$1"
}

mkrepo "$T/work" main                 # on main, the default branch
mkrepo "$T/feat" main; git -C "$T/feat" switch -qc feature-x
mkrepo "$T/trunk" trunk               # the default branch isn't called main
git init -q -b main "$T/noremote"     # no origin, so the name is the only clue
git -C "$T/noremote" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m base
git init -q -b main "$T/fresh"        # no commits yet
mkdir "$T/plain"                      # not a git repo

check "a commit on the default branch is denied"            deny  "$T/work"  'git commit -m "x"'
check "a commit on a feature branch is allowed"             allow "$T/feat"  'git commit -m "x"'
check "git -C into a repo on its default branch is denied"  deny  "$T/plain" "git -C $T/work commit -m x"
check "cd into a repo on its default branch is denied"      deny  "$T/plain" "cd $T/work && git add -A && git commit -m x"
check "cd into a repo on a feature branch is allowed"       allow "$T/work"  "cd $T/feat && git commit -m x"
check "the default branch comes from origin/HEAD"           deny  "$T/trunk" 'git commit -m x'
check "with no origin, main counts as the default branch"   deny  "$T/noremote" 'git commit -m x'
check "the first commit of a new repo is allowed"           allow "$T/fresh" 'git commit -m "init"'
check "a wrapped git commit is still denied"                deny  "$T/work"  'rtk git commit -m x'
check "git options before the subcommand don't hide it"     deny  "$T/work"  'git -c user.name=t --no-pager commit -m x'
check "other git commands on the default branch are allowed" allow "$T/work" 'git status && git log --grep commit'
check "a commit outside any repo is allowed"                allow "$T/plain" 'git commit -m x'
check "merging a PR asks the user"                          ask   "$T/feat"  'gh pr merge 12 --squash'
check "approving a PR asks the user"                        ask   "$T/feat"  'gh pr review 12 --approve'
check "commenting on a PR is allowed"                       allow "$T/feat"  'gh pr review 12 --comment -b "note"'
check "viewing a PR is allowed"                             allow "$T/feat"  'gh pr view 12 --json state'

reason="$(jq -n --arg cwd "$T/work" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:"git commit -m x"}}' \
  | bash "$GATE" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')"
if [[ "$reason" == *"git switch"* ]]; then echo "ok   - a denial says how to proceed"; else echo "FAIL - a denial says how to proceed"; fail=1; fi

# --- Rule 3: a stage is approved only with its tools accounted for ------------
mkrepo "$T/led" main; git -C "$T/led" switch -qc feature-y
L="$T/led/docs/sdlc/demo"; mkdir -p "$L/egm" "$L/pr-review"
# state <lines...> writes sdlc.yaml with an approved intent, which HEAD already has, and the given stage lines.
state() {
  { printf 'feature: demo\nstages:\n  intent: {status: approved, owner: Sam, approver: Lee, artifact: intent.md}\n'
    printf '%s\n' "$@"; } > "$L/sdlc.yaml"
}
state '  spec: {status: draft, owner: Sam, approver: Lee, artifact: spec.md}'
git -C "$T/led" add -A; git -C "$T/led" -c user.email=t@example.com -c user.name=t commit -qm "draft spec"
c='git add -A && git commit -m x'

check "a stage approved before the ledger existed doesn't block a commit" allow "$T/led" "$c"
state '  spec: {status: approved, owner: Sam, approver: Lee, artifact: spec.md}'
check "approving a stage with no tools recorded is denied"   deny  "$T/led" "$c"
state '  spec: {status: approved, artifact: spec.md, tools: {goldfish: egm/spec-review.md}}'
check "a tool whose file is missing is denied"               deny  "$T/led" "$c"
touch "$L/egm/spec-review.md"
check "a tool with the file it produced is allowed"          allow "$T/led" "$c"
state '  spec: {status: approved, artifact: spec.md, tools: {goldfish: "skipped: one-line change, Lee agreed"}}'
check "a skipped tool with a reason is allowed"              allow "$T/led" "$c"
state '  spec: {status: approved, artifact: spec.md, tools: {goldfish: skipped}}'
check "a skipped tool with no reason is denied"              deny  "$T/led" "$c"
state '  spec: {status: skipped, reason: "typo fix, Lee agreed"}'
check "a skipped stage needs no tools"                       allow "$T/led" "$c"
touch "$L/pr-review/build-1.md"
state '  build: {status: approved, tools: {pr-review: pr-review/build-1.md}}'
check "one tool on record doesn't cover the stage's other tool" deny "$T/led" "$c"
state '  build: {status: approved, tools: {ponytail: pr-review/build-1.md, pr-review: pr-review/build-1.md}}'
check "Build isn't approved without the testing toolkit on record" deny "$T/led" "$c"
mkdir -p "$L/testing"; touch "$L/testing/build.md" "$L/verify.md"
state '  build: {status: approved, tools: {ponytail: pr-review/build-1.md, testing: testing/build.md, pr-review: pr-review/build-1.md}}'
check "every required tool on record is allowed"             allow "$T/led" "$c"
state '  test: {status: approved, artifact: verify.md, tools: {verifier: verify.md, pr-review: pr-review/build-1.md}}'
check "Test isn't approved without the testing toolkit on record" deny "$T/led" "$c"
state '  spec:' '    status: approved' '    tools:' '      goldfish: egm/spec-review.md'
check "a block-style entry is read the same way"             allow "$T/led" "$c"
state '  spec:' '    status: approved' '    tools:' '      goldfish: skipped' '    artifact: spec.md'
check "a block-style skip with no reason is denied"          deny  "$T/led" "$c"

state '  spec: {status: draft}'
mkdir -p "$T/led/docs/sdlc/new"
printf 'feature: new\nstages:\n  intent: {status: approved, owner: Sam}\n' > "$T/led/docs/sdlc/new/sdlc.yaml"
check "a new feature's first approval is checked too"        deny  "$T/led" "$c"
rm -r "$T/led/docs/sdlc/new"

state '  spec: {status: approved, artifact: spec.md}'
reason="$(jq -n --arg cwd "$T/led" --arg c "$c" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$c}}' \
  | bash "$GATE" 2>/dev/null | jq -r '.hookSpecificOutput.permissionDecisionReason')"
if [[ "$reason" == *spec*goldfish* && "$reason" == *"skipped: <reason>"* ]]; then echo "ok   - the denial names the stage, the tool and the way out"; else echo "FAIL - the denial names the stage, the tool and the way out ($reason)"; fail=1; fi

# --- status: one line per feature in flight -----------------------------------
S="$T/status"; mkdir -p "$S/docs/sdlc/bulk-export" "$S/docs/sdlc/sso-login" "$S/docs/sdlc/shipped"
printf 'stages:\n  intent: {status: approved}\n  spec: {status: approved}\n  rfc: {status: skipped, reason: "x"}\n  plan: {status: approved}\n  build: {status: draft, owner: Sam}\n' > "$S/docs/sdlc/bulk-export/sdlc.yaml"
printf '| 1 | A | done |\n| 2 | B | in_progress |\n| 3 | C | pending |\n' > "$S/docs/sdlc/bulk-export/plan.md"
printf 'stages:\n  intent:\n    status: approved\n  spec:\n    status: draft\n    owner: Priya\n    approver: Lee\n' > "$S/docs/sdlc/sso-login/sdlc.yaml"
{ echo 'stages:'; for s in intent spec rfc plan build test ship adr maintain; do echo "  $s: {status: approved}"; done; } > "$S/docs/sdlc/shipped/sdlc.yaml"
out="$(CLAUDE_PROJECT_DIR="$S" bash "$GATE" status 2>&1 </dev/null)"
expect() { if eval "$2"; then echo "ok   - $1"; else echo "FAIL - $1"; fail=1; fi; }
expect "status names the stage a feature is at"            '[[ "$out" == *"bulk-export: at build"* && "$out" == *"sso-login: at spec"* ]]'
expect "status counts the build phases that are done"      '[[ "$out" == *"1 of 3"* ]]'
expect "status names the owner and the approver"           '[[ "$out" == *"Priya"* && "$out" == *"Lee"* ]]'
expect "status leaves out a person the entry doesn't name"   '[[ "$(grep bulk-export <<<"$out")" == *"Owner Sam"* && "$(grep bulk-export <<<"$out")" != *pprover* ]]'
expect "status leaves out a feature with every stage done" '[[ "$out" != *shipped* ]]'
expect "status points at the sdlc skill"                   '[[ "$out" == *"sdlc skill"* ]]'
expect "status prints nothing in a repo without the loop"  '[ -z "$(CLAUDE_PROJECT_DIR="$T/plain" bash "$GATE" status 2>&1 </dev/null)" ]'

exit "$fail"
