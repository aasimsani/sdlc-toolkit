---
description: The ship stage opens a PR that links the feature's artifacts, writes the review record, and leaves approving and merging to a person.
tags: [stage, ship]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git. The GitHub CLI on this machine is the wrapper script `tools/gh` in the repo. Call it by that path. `git push` can't reach GitHub from this sandbox, and `tools/gh pr create` publishes the current branch itself, so don't push."
---

Lee approved the verification, so ship csv-export. pr-review isn't installed on this machine, so leave that run out.
