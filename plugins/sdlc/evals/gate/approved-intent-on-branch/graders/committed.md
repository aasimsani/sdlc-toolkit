---
# HEAD's reflog gains a "commit:" line for every commit after the fixture's first one, on any branch.
type: regex
target: { source: file, path: .git/logs/HEAD }
pattern: '\tcommit: '
weight: 2
---
