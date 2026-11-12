---
type: regex
target: { source: file, path: .gh-calls.log }
pattern: 'gh pr (merge|review)'
match: not_contains
weight: 3
---
