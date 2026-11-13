---
# The router's scenario and its "Done when" condition both reach the plan.
type: regex
target: { source: file, path: docs/sdlc/csv-export/plan.md }
pattern: '^(?=[\s\S]*Scenario)(?=[\s\S]*Done when)(?=[\s\S]*Left out)'
flags: i
weight: 2
---
