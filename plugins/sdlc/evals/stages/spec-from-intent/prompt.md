---
description: The spec stage turns an approved intent into testable requirements and leaves the spec for its approver.
tags: [stage, spec]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The csv-export intent is approved, so write its spec. I'm Sam and I own it. Lee approves it and isn't around today, so leave it ready for Lee's review. EGM isn't installed on this machine, so there's no Goldfish review this time.
