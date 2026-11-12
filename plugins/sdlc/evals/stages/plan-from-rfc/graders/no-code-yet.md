---
# Planning changes no code, so the command still has no csv option.
type: regex
target: { source: file, path: bin/invoices }
pattern: 'csv'
match: not_contains
weight: 2
---
