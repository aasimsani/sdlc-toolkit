---
# tools/record-demo logs each call. The stage tries the repo's own recorder before anything else.
type: regex
target: { source: file, path: .record-calls.log }
pattern: 'record-demo site/index\.html'
weight: 3
---
