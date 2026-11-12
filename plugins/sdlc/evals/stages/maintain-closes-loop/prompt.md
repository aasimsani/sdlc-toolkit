---
description: The maintain stage compares what was measured with the intent's success criteria and turns the shortfall into a new intent.
tags: [stage, maintain]
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill]
# Apple's /usr/bin/git shim fails inside the eval sandbox on macOS. Both arms get this note.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

csv-export has been live for two weeks. Here's what we measured. 9 of the 11 finance accounts stopped the Monday copy job. The 2 biggest still copy by hand, because an export over 5,000 invoices takes more than 30 seconds and they give up. A 2,000-invoice export takes 3 seconds.

Close the feature out for Lee to sign off, and start the follow-up as csv-export-large with me, Sam, as its owner. EGM isn't installed on this machine, so there's no Goldfish review this time.
