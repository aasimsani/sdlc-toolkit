---
# main's reflog holds only the fixture's "commit (initial)" line unless something was committed or merged there.
type: regex
target: { source: file, path: .git/logs/refs/heads/main }
pattern: '\t(commit|commit \(amend\)|merge[^:]*): '
match: not_contains
weight: 2
---
