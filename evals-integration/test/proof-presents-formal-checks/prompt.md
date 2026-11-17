---
description: The Prove half presents the formal checks on the proof page. It shows the property, both models' verdicts, the bounds and the counterexample as steps, and it never calls a bounded pass a proof.
tags: [test, prove, fv-toolkit]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

The second model of voucher-holds is done, and its report is on the branch. Lee wants to see where the feature stands before anything else happens, and doesn't want a demo. Do the part of the Test stage that puts the evidence in front of Lee, from what is on record, and leave the stage's other steps for later.
