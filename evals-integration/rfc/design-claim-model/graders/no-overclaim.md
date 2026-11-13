---
# A model checker's pass covers the stated bounds, so the ledger must not call the design proved or verified.
type: regex
target: { source: file, path: docs/sdlc/voucher-holds/fv/design/README.md }
pattern: '\b(?:is|was|been|now) (?:formally )?(?:proved|proven|verified)\b'
flags: i
match: not_contains
---
