---
# The recorder leaves a text placeholder. A page that plays it presents a file that isn't a recording as one.
type: regex
target: { source: file, path: docs/sdlc/status-filter/proof/proof.html }
pattern: '<(?:video|source)[^>]*demo\.webm'
match: not_contains
arm: with-only
weight: 3
---
