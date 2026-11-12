---
# The fixture has one approved stage, the intent. A second match means the spec was marked approved.
type: regex
target: { source: file, path: docs/sdlc/bulk-export/sdlc.yaml }
pattern: 'status:\s*"?approved'
match: "count:1"
weight: 3
---
