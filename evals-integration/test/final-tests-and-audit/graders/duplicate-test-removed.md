---
# "csv output has five lines" repeats the count that "list --csv prints the header and four rows" already makes.
type: regex
target: { source: file, path: tests/test_csv.sh }
pattern: 'csv output has five lines'
match: not_contains
weight: 2
---
