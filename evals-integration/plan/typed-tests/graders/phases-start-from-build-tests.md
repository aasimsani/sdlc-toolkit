---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/plan.md }
weight: 2
---

The file is an implementation plan. Its Phases table names a first failing test for each phase, and its Tests table says which stage writes each test.

PASS if every phase's first failing test is a test that the Tests table assigns to Build.
