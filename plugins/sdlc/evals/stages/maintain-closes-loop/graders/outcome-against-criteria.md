---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/lessons.md }
weight: 3
---

The file closes out a shipped feature. Its two success criteria were "Finance stops copying invoices by hand" and "an export of 2,000 invoices finishes in under 5 seconds". The measurements were: 9 of 11 accounts stopped copying, 2 still copy by hand because exports over 5,000 invoices take more than 30 seconds, and a 2,000-invoice export takes 3 seconds.

PASS only if all of these hold:
- It compares each of the two criteria with its measurement.
- It says the first criterion is not met, or only partly met.
- It says the second criterion is met.

FAIL if it says both criteria are met, or reports different results for these two criteria than the measurements above.
