---
# The plan gives tests/final/test_perf.sh to the Test stage, so Build writes nothing there.
type: file_exists
path: "tests/final/*"
exists: false
weight: 2
---
