---
description: Test writes the final test the plan left for it, checks the tests Build wrote, and ends its work on the tests with the audit, which removes an assertion-free test.
tags: [test, testing-toolkit]
max_turns: 150
timeout_seconds: 2700
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The csv-export build is finished. Run the Test stage: check the feature against its spec and write up the evidence for Lee. pr-review isn't installed on this machine, so leave that run out.
