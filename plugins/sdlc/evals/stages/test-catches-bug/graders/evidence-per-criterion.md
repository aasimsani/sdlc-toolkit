---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/verify.md }
weight: 2
---

The file is a verification report for a feature with five acceptance criteria, AC1 to AC5. AC5 is a speed target of 2,000 invoices in under 5 seconds.

PASS only if all of these hold:
- Each of AC1 to AC5 has its own result.
- Each result comes with evidence a reader could check, such as a test name, a command with its output, or a measured time.
- AC5 has a measured time, or is listed as untested. It is not marked as passing without a number.

FAIL otherwise.
