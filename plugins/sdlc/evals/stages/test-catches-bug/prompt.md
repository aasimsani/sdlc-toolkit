---
description: The test stage finds an acceptance criterion that the green test suite misses, records it as failing, and sends the feature back to Build without approving.
tags: [stage, test]
max_turns: 80
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The csv-export build is finished. Run the Test stage: check the feature against its spec and write up the evidence for Lee. pr-review isn't installed on this machine, so leave that run out.
