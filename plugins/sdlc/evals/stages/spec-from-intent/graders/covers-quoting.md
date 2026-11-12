---
# The sample data has a customer with a comma and one with a double quote. A spec written after reading it says how those export.
type: regex
target: { source: file, path: docs/sdlc/csv-export/spec.md }
pattern: 'quot|escap|4180'
flags: i
weight: 2
---
