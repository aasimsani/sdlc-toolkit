---
description: The plan stage maps every acceptance criterion to a test, starts each phase with a failing test, and writes todos for the first phase only.
tags: [stage, plan]
max_turns: 50
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

Write the plan for csv-export. I'm away from my keyboard for the next hour, so don't use plan mode. Write plan.md directly and leave it ready for Lee's review. EGM and the testing toolkit aren't installed on this machine, so there's no Goldfish review this time, and you choose the tests yourself.
