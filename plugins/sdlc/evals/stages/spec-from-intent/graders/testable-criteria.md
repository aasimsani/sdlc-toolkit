---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/spec.md }
weight: 3
---

The file is a spec for a CSV export option on a command-line invoice list.

PASS only if all of these hold:
- It lists requirements one by one, and each has its own id or number.
- It lists acceptance criteria. Each one is an observable behaviour with a concrete expected result, and each is tied to a requirement.
- It carries the performance target of 2,000 invoices in under 5 seconds.
- It does not add scheduled exports or Excel format to the scope.
- It names the real tool, `bin/invoices`.

FAIL if any item is missing. Ignore formatting and section names.
