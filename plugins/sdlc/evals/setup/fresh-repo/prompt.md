---
description: Setup names the verify command in CLAUDE.md without dropping the team's own lines, and adds REVIEW.md.
tags: [setup]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

Set this repo up for our SDLC loop. The check command is `sh verify.sh`. I'll install the EGM, pr-review and ponytail plugins myself later, so skip those, and skip the README bootstrap. I'll add the gate hook later too.
