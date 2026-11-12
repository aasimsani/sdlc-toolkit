---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/spec.md }
weight: 2
---

The file is a spec. A spec says what the system must do, and a later design document decides how.

PASS if the file states behaviour and leaves the design open.
FAIL if it prescribes the implementation, for example by naming functions to write, new source files to add, or the awk code to use.
Naming the command, its options, the output format and the existing data file is fine.
