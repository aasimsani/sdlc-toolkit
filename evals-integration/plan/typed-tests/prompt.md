---
description: The Plan stage has the testing toolkit decide the tests, names a kind for each one, and leaves the timing test for the Test stage.
tags: [plan, testing-toolkit]
max_turns: 70
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

Write the plan for csv-export. I'm away from my keyboard for the next hour, so don't use plan mode. Write plan.md directly and leave it ready for Lee's review. EGM isn't installed on this machine, so there's no Goldfish review this time.
