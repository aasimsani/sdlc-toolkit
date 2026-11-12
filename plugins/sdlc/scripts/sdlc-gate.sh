#!/usr/bin/env bash
# sdlc-gate.sh — a Claude Code PreToolUse hook for the Bash tool.
# It backs two rules of the sdlc loop with a check that doesn't depend on Claude
# following prose:
#   1. Nothing commits on the default branch. The hook denies the command.
#   2. A human approves and merges a PR. The hook makes Claude Code ask the user.
# sdlc:setup copies this file to .claude/hooks/ in a repo that opts in.
# Requires jq. Test with: bash tests/test_gate.sh

set -uo pipefail
# Without jq the hook can't read its input. It allows the command, because a
# hook that blocks every Bash call would stop all work in the repo.
command -v jq >/dev/null || exit 0

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -n "$cmd" ] || exit 0

decide() {                            # args: allow|ask|deny reason
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

start='(^|[;&|({[:space:]])'          # where a command word may begin

# --- Rule 2: approving or merging a PR is the human's call --------------------
# ponytail: this matches the gh CLI only. Add `gh api .../merge` or another
# forge's CLI here if the team merges that way.
if [[ "$cmd" =~ ${start}gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$) ]] ||
   [[ "$cmd" =~ ${start}gh[[:space:]]+pr[[:space:]]+review[^\;\&\|]*[[:space:]](--approve|-a)([[:space:]]|$) ]]; then
  decide ask "The sdlc loop leaves approving and merging a PR to a human. Confirm only if you asked Claude to do this."
fi

# --- Rule 1: no commits on the default branch -------------------------------
# Global git options such as `-C dir`, `-c key=value` and `--no-pager` may sit
# between `git` and the subcommand.
commit_re="${start}git([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+commit([[:space:]]|\$)"
[[ "$cmd" =~ $commit_re ]] || exit 0

# Find the repo the commit runs in.
# ponytail: this reads `git -C dir` and the first `cd dir`. A command that changes
# directory some other way (pushd, a subshell, a variable) is checked against the
# session's cwd instead. Parse the command properly if that ever lets one through.
dir="$cwd"
if [[ "$cmd" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  dir="${BASH_REMATCH[1]}"
elif [[ "$cmd" =~ ${start}cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
  dir="${BASH_REMATCH[2]}"
fi
dir="${dir%\"}"; dir="${dir#\"}"; dir="${dir%\'}"; dir="${dir#\'}"
dir="${dir/#\~/$HOME}"
dir="$(cd "${cwd:-.}" 2>/dev/null && cd "$dir" 2>/dev/null && pwd)" || exit 0

current="$(git -C "$dir" branch --show-current 2>/dev/null)" || exit 0
[ -n "$current" ] || exit 0           # not a repo, or a detached HEAD
git -C "$dir" rev-parse --verify --quiet HEAD >/dev/null || exit 0   # a new repo's first commit

default="$(git -C "$dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
default="${default#origin/}"
if [ -n "$default" ]; then
  [ "$current" = "$default" ] || exit 0
else
  # With no origin/HEAD to read, the conventional names are the only clue.
  case "$current" in main|master) ;; *) exit 0 ;; esac
fi

decide deny "The sdlc loop never commits on the default branch (${current}). Switch to the feature branch recorded in docs/sdlc/<slug>/sdlc.yaml, or create one with \`git switch -c <branch>\`, then commit again."
