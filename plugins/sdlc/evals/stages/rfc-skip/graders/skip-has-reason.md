---
# The fixture's sdlc.yaml has no reason field, so one appears only when the skip records why.
type: regex
target: { source: file, path: docs/sdlc/csv-export/sdlc.yaml }
pattern: 'reason:'
---
