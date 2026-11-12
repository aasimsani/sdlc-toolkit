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

exit "$fail"
