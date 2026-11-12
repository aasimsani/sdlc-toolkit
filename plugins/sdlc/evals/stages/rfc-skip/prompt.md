---
description: When the approver skips the RFC for a low-risk spec, the skip is recorded with its reason and the ADR is skipped with it.
tags: [stage, rfc]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

I'm Lee, the approver. The csv-export spec is approved and low-risk, and the change is one flag on one command, so I'm skipping the RFC. Record that, then tell me which stage is next and who it's waiting on. Don't start that stage.
