---
description: The ADR stage writes a record of what shipped, lists where it departs from the RFC, and leaves the RFC unchanged.
tags: [stage, adr]
max_turns: 50
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

PR 42 for csv-export merged on 2026-11-08. Write the ADR and leave it ready for Lee's review. EGM isn't installed on this machine, so compare the RFC with the code yourself.
