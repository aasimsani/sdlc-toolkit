---
# Nobody answered, so the stage's tools carry no demo entry. A recorded skip would mean Claude answered for Lee.
type: regex
target: { source: file, path: docs/sdlc/csv-export/sdlc.yaml }
pattern: 'demo:'
match: not_contains
arm: with-only
weight: 3
---
