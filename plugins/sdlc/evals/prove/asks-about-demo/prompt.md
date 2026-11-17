---
description: The Test & Prove stage builds the proof page and asks the approver whether they want a demo, without answering for them.
tags: [stage, test, prove]
max_turns: 100
timeout_seconds: 1500
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The csv-export build is finished. Run the Test stage and get the evidence ready for Lee, who reads it tomorrow and can't answer anything today. pr-review and the testing toolkit aren't installed on this machine, so leave those runs out.
