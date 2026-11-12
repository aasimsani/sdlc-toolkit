---
# The PR body, which the gh stand-in logs, points the reviewer at the spec and the verification evidence.
type: regex
target: { source: file, path: .gh-calls.log }
pattern: '^(?=[\s\S]*spec\.md)(?=[\s\S]*verify\.md)'
weight: 2
---
