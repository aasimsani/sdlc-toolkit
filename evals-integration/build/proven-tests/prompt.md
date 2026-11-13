---
description: Build has the testing toolkit write the phase's Build tests first, proves each one can fail, saves the report, and leaves the final test for the Test stage.
tags: [build, testing-toolkit]
max_turns: 110
timeout_seconds: 1800
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

Build phase 1 of csv-export, and stop when that phase is finished. pr-review and ponytail aren't installed on this machine, so carry on without them.
