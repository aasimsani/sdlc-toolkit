---
# "export never crashes" ends with `true`, so it passes whatever the command does. The audit removes it or gives it a real assertion.
type: regex
target: { source: file, path: tests/test_csv.sh }
pattern: 'export never crashes[^\n]*; true'
match: not_contains
weight: 2
---
