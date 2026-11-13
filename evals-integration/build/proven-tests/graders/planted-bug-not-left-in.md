---
# A planted bug is restored afterwards, so the table output still starts with the header line it had.
type: regex
target: { source: file, path: bin/invoices }
pattern: 'printf "%-8s %-22s %10s  %s\\n"'
weight: 2
---
