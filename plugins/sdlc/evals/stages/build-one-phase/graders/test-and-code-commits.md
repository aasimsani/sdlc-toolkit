---
# The fixture leaves five "commit:" lines in HEAD's reflog. Two more mean the phase landed as at least two commits,
# which is what committing the failing test before the code produces.
type: regex
target: { source: file, path: .git/logs/HEAD }
pattern: '(?:\tcommit: [^\n]*\n[\s\S]*?){7}'
---
