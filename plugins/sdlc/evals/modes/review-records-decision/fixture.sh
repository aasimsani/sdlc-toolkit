#!/usr/bin/env bash
# Seeds the empty workspace for this case. `claude plugin eval --scaffold` runs it.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib/lifecycle.sh"
seed intent
# Priya drafted the spec. Its AC5 gives no number, which is what Lee asks her to change.
art_spec
sed "s/finishes in under 5 seconds\. | Non-functional/is fast. | Non-functional/" "$F/spec.md" > "$F/spec.tmp" && mv "$F/spec.tmp" "$F/spec.md"
echo "  spec: {status: draft, owner: Priya, approver: Lee, artifact: \"spec.md\"}" >> "$F/sdlc.yaml"
git add -A && git commit -q -m "docs(sdlc): draft spec for csv-export"
