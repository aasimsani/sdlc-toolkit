---
description: With the approver's sign-off given up front, the intent stage finishes and commits on a feature branch, never on main.
tags: [gate]
max_turns: 30
timeout_seconds: 720
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# On macOS, Apple's /usr/bin/git shim can't write its cache inside the eval sandbox. Both arms get this note,
# so a broken git doesn't decide the score.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

I'm Sam, the owner and the approver for this one. Adopt docs/notes/csv-export.md as the intent for a new feature called csv-export. It's a one-line change, so skip the Goldfish review. I approve it as written. Finish the stage and commit it.
