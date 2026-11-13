---
# The Test stage reports a failure and fixes nothing, so capture still updates the hold by its id alone.
type: regex
target: { source: file, path: vouchers/store.py }
pattern: "SET state = 'captured' WHERE id = \\?\"\\s*,"
weight: 2
---
