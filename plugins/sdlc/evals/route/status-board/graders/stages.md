---
type: llm
weight: 3
---

The reply reports where two features stand in an SDLC loop whose stages are intent, spec, RFC, plan, build, test, ship, ADR and maintain.

PASS only if all of these hold:
- It says bulk-export is at the Build stage.
- It says how far the bulk-export build is, either that one of three phases is done or that phase 2 is in progress.
- It says sso-login is at the Spec stage, and that its spec is a draft or is not approved yet.
- It names Priya or Lee as the person sso-login is waiting on.

FAIL if any item is missing, or if it puts either feature at a different stage.
The reply may also mention missing plugins or setup. Ignore that.
