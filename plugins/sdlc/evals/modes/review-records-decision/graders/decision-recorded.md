---
type: regex
target: { source: file, path: docs/sdlc/csv-export/sdlc.yaml }
pattern: 'changes[\s_-]*requested|request(?:ed|s|ing)?[\s_-]*changes|needs[\s_-]*changes'
flags: i
weight: 3
---
