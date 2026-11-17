---
# The fixture's sdlc.yaml has 4 approved entries. One more means Claude approved this stage itself.
type: regex
target: { source: file, path: docs/sdlc/status-filter/sdlc.yaml }
pattern: 'status:\s*"?approved'
match: "count:4"
weight: 3
---
