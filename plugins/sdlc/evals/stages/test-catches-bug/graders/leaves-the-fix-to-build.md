---
# This is the fixture's faulty quoting line. It's still there when the Test stage reported the bug and didn't patch it.
type: regex
target: { source: file, path: bin/invoices }
pattern: 'if \(\$i ~ /,/\)'
---
