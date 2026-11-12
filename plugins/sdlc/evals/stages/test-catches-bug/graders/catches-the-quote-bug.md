---
# The fixture's export quotes a field with a comma but not one with a double quote, and no test covers that row.
type: llm
focus: { source: file, path: docs/sdlc/csv-export/verify.md }
weight: 4
---

The file is a verification report for a CSV export. Acceptance criterion AC3 requires the row `INV-004,"Initech ""West""",4500.00,open`. The code under test actually prints `INV-004,Initech "West",4500.00,open`, so AC3 is not met.

PASS only if the report says AC3 fails, or is only partly met, because a field with a double quote is not quoted or escaped.
FAIL if the report marks AC3 as passing, or says every criterion passes.
