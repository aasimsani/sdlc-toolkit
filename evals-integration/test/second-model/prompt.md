---
description: The Test stage checks the pinned properties, dispatches the fv-verifier subagent to model the code afresh, and sends the feature back to Build when the code breaks a property the design kept.
tags: [test, fv-toolkit]
max_turns: 160
timeout_seconds: 3300
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The voucher-holds build is finished, and Lee wants the formal part of the Test stage first. Do the stage's step that models the code afresh, deal with what it finds the way the stage says, and tell me. Leave the stage's other steps for later.
