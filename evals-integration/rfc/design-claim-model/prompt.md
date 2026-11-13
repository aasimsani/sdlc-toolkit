---
description: The RFC stage has the fv-toolkit model the design, the model checker finds the order of steps that breaks the claim, and the design changes before any code exists.
tags: [rfc, fv-toolkit]
max_turns: 160
timeout_seconds: 3000
allowed_tools: [Read, Write, Edit, Bash, Glob, Grep, Skill, Agent]
# Apple's /usr/bin/git launcher fails inside the eval sandbox on macOS.
append_system_prompt: "Environment note: if `git` fails with an xcrun or xcode-select error, call a git binary by its full path, such as /opt/homebrew/bin/git or /Library/Developer/CommandLineTools/usr/bin/git."
---

I'm Sam, and the voucher-holds RFC draft is mine. Run the RFC stage's check of the design's claims on it.

Lee has already confirmed this property, so don't wait for that: "The total captured against a voucher never exceeds its face value."

If the check finds a flaw, change the design in rfc.md so the property holds, and leave the stage ready for Lee's review. EGM and the rfc skill aren't installed on this machine, so work on rfc.md as it is and leave the Goldfish review out.
