---
# verify.sh keeps its last summary line here. The fixture has three checks, so a passing build has four or more.
type: regex
target: { source: file, path: .verify-last }
pattern: '^(?:[4-9]|\d\d+) passed, 0 failed'
weight: 3
---
