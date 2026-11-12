---
description: The build stage runs a failing test before it writes the code, gets the verify command green, and stops at the end of the phase it was given.
tags: [stage, build]
max_turns: 80
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

Build phase 1 of csv-export, and stop when that phase is finished. pr-review, ponytail and the testing toolkit aren't installed on this machine, so carry on without them.
