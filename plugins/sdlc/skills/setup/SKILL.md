---
name: setup
description: One-time setup that prepares a repo, and this machine, for the /sdlc loop. Installs the EGM, pr-review and ponytail plugins if they're missing, and sets up CLAUDE.md, one verify command, REVIEW.md and docs/sdlc/. Use when the user runs /sdlc:setup, or when the sdlc skill reports that something is missing.
---

# SDLC setup (once per machine, once per repo)

Read `${CLAUDE_PLUGIN_ROOT}/references/tools.md` first.

## Machine

1. **Check Claude Code.** Run `claude --version`. EGM needs 2.1.271 or later to isolate its Goldfish reviewers. If the version is older, tell the user to update before using the loop.

2. **Install EGM** if `claude plugin list --json` shows no enabled `egm@` plugin. Ask first, then run:
   ```bash
   claude plugin marketplace add google/elephant-goldfish-model
   claude plugin install egm@egm
   ```

3. **Install pr-review** if no enabled `pr-review@` plugin exists. Ask first, then run:
   ```bash
   claude plugin marketplace add aasimsani/pr-review
   claude plugin install pr-review@aasimsani-pr-review
   ```
   If the `claude plugin list --json` output shows two enabled `pr-review@` plugins, ask the user which one to keep and disable the other. Two copies share the skill name `pr-review:pr-review`.

4. **Install ponytail** if no enabled `ponytail@` plugin exists. Ask first, then run:
   ```bash
   claude plugin marketplace add DietrichGebert/ponytail
   claude plugin install ponytail@ponytail
   ```

5. **Check pr-review's tools.** Make sure `gh auth status` passes and `jq` is on `PATH`.

6. **Restart.** If you installed anything, tell the user to start a new session so the plugins load.

## Repo

1. **CLAUDE.md.** If the repo has no `CLAUDE.md`, generate one with `/init` and trim it. Make sure it has these four sections and stays under one page:
   - `## Commands` lists build, test, lint, the run command, and one **verify command**, such as `make verify`. It also says what healthy output looks like, for example "ends with `N passed, 0 failed`".
   - `## Conventions` lists naming, layout and error-handling rules the code already follows.
   - `## Architecture` gives a few lines on the main components and how a request flows through them.
   - `## Things Claude gets wrong` starts empty. Stages add to it when a mistake happens twice.

   Don't overwrite an existing `CLAUDE.md`. Add only the missing sections, and show the diff before you write it.

2. **Verify command.** Find an existing command that runs tests, lint and type checks together. If none exists, ask which checks it should run, and add one target, such as a Makefile target or a package script. Run it once and record the result.

3. **REVIEW.md.** pr-review appends this file to every review prompt. If the repo has none, write this template and ask the tech lead to adjust it:

   ```markdown
   # Review rules

   ## What counts as an issue
   1. Bugs: logic errors, unhandled edge cases, broken contracts with callers.
   2. Security: authentication, input validation, secrets, PII handling.
   3. Compliance: anything the team's policies or CLAUDE.md require.
   4. Tests: every new behavior has a test that fails without the change.

   ## What never counts
   - Style and naming taste the formatter or linter doesn't enforce.
   - Generated files and lockfiles.
   ```

4. **Directory READMEs (optional).** Offer to run `egm-bootstrap` on the repo root, or on the subtree the team owns. It writes a `README.md` per directory, and Goldfish reviewers read those as their baseline. It's a large run, so ask before starting.

5. **Artifact home.** Create `docs/sdlc/README.md` with one line saying that each subfolder holds one feature's artifacts and its `sdlc.yaml`.

6. **Optional guardrail hooks.** Ask whether the user wants project hooks in `.claude/settings.json`, and add them only if they say yes. Common choices are running the formatter after each edit, blocking edits to generated or vendored paths, and blocking writes that contain credentials.

7. **Commit.** Show the full diff, get approval, and commit it on a branch as `chore(sdlc): set up repo for the sdlc loop`, or the repo's equivalent.
