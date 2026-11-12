---
type: llm
focus: { source: file, path: docs/sdlc/csv-export/plan.md }
weight: 2
---

The file is an implementation plan with several phases.

PASS only if it has a checklist of unchecked todo items, written as `- [ ]`, for the first phase, and no todo checklist for any later phase. Later phases may be described in prose or in a table.
FAIL if it has no `- [ ]` items at all, or if more than one phase has them.
