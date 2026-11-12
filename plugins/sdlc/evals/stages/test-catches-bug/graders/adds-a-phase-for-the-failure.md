---
# The fixture's plan has two phases. The stage adds a third for the failing criterion.
type: regex
target: { source: file, path: docs/sdlc/csv-export/plan.md }
pattern: '\|\s*3\s*\|'
---
