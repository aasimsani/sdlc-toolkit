---
# tests/lib.sh appends every check result to .test-log, in the order the checks ran.
# This passes when a csv check failed before a csv check passed, so the test existed and was run before the code did.
type: regex
target: { source: file, path: .test-log }
pattern: 'FAIL - [^\n]*csv[^\n]*\n[\s\S]*ok - [^\n]*csv'
flags: i
weight: 3
---
