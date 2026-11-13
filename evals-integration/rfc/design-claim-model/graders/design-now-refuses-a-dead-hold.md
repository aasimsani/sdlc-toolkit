---
type: llm
focus: { source: file, path: docs/sdlc/voucher-holds/rfc.md }
weight: 3
---

The file is a design for holds on gift vouchers. A till places a hold, captures it when the sale completes, and a sweeper releases a hold that has expired.

PASS if the capture step captures a hold only while the hold is still live.
