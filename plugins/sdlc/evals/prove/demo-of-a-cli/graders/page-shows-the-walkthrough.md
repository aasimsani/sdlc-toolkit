---
# The page escapes the quotes of the output row, or keeps them.
type: regex
target: { source: file, path: docs/sdlc/csv-export/proof/proof.html }
pattern: 'INV-002,(?:"|&quot;|&#34;|&#x22;)Acme, Inc\.'
weight: 3
---
