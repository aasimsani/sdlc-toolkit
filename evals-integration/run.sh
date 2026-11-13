#!/usr/bin/env bash
# Runs the integration suite: sdlc stages with the testing toolkit and the fv-toolkit loaded beside the sdlc plugin.
# Usage: evals-integration/run.sh [more `claude plugin eval` flags, such as --case <glob> or --runs 1]
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

# A case may load only plugins that sit under the directory the eval runs against, so the installed toolkits are copied in.
for id in testing-toolkit@testing-toolkit fv-toolkit@formal-verification-toolkit; do
  src="$(claude plugin list --json | jq -r --arg id "$id" '.[] | select(.enabled and .id == $id) | .installPath')"
  [ -d "$src" ] || { echo "$id isn't installed. Run /sdlc:setup first." >&2; exit 1; }
  rm -rf "$root/.toolkits/${id%%@*}"
  mkdir -p "$root/.toolkits"
  cp -R "$src" "$root/.toolkits/${id%%@*}"
  echo "using $id $(jq -r .version "$src/.claude-plugin/plugin.json")"
done

# On macOS, /usr/bin/java and /usr/bin/python3 are launchers that fail inside the eval sandbox, so real binaries go first.
jdk="$(/usr/libexec/java_home 2>/dev/null || true)"
export PATH="${jdk:+$jdk/bin:}/opt/homebrew/bin:$PATH"

cd "$root"
# One arm, because under the two-arm mode a grader on a Skill call isn't scored, and those calls are what this suite measures.
exec claude plugin eval . --eval-dir evals-integration --scaffold --trust-plugin --allow-tools Bash Write Edit \
  --ablation none --model claude-sonnet-5-5 --judge-model claude-sonnet-5-5 "$@"
