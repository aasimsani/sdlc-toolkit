---
# The plan's Tests table says which stage writes each test.
type: regex
target: { source: file, path: docs/sdlc/csv-export/plan.md }
pattern: 'Written in'
flags: i
weight: 2
---
