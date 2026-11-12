---
description: In review mode Claude records the approver's decision on a teammate's spec and doesn't edit the spec.
tags: [mode, review]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

I'm Lee, the approver for the csv-export spec. Priya wrote it. I've read it, and I'm requesting changes: AC5 says the export "is fast" and gives no number. Record my decision so Priya sees it.
