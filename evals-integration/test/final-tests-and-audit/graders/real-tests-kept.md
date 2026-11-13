---
# The audit must not remove the two quoting checks, because each one owns a contract.
type: regex
target: { source: file, path: tests/test_csv.sh }
pattern: '^(?=[\s\S]*a customer with a comma is quoted)(?=[\s\S]*a customer with a double quote is quoted)'
weight: 3
---
