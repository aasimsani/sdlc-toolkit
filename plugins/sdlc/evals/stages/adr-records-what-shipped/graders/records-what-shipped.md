---
# The RFC chose a lib/csv.awk file and two PRs. The code quotes inline in bin/invoices, and one PR delivered it.
type: llm
focus: { source: file, path: docs/sdlc/csv-export/adr.md }
weight: 4
---

The file is an architectural decision record for a CSV export. The earlier RFC proposed putting the quoting function in a new file, `lib/csv.awk`. What shipped has the quoting inline in `bin/invoices`, and `lib/csv.awk` doesn't exist.

PASS only if all of these hold:
- It states that the quoting is inline in `bin/invoices`.
- It says this departs from the RFC's `lib/csv.awk` proposal, and gives a reason.
- It names pull request 42.

FAIL if it presents `lib/csv.awk` as what was built, or doesn't mention the departure.
