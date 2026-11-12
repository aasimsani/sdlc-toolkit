# Running the testing toolkit

The [testing toolkit](https://github.com/aasimsani/testing-toolkit) decides which kinds of test a change needs and writes them from the spec. Its `testing` skill classifies the change, picks a kind of test for each component and calls the toolkit's other skills in order. Invoke `testing-toolkit:testing` with the Skill tool, and let it choose the other skills. `sdlc:setup` installs it.

The skill does its whole job in one pass, after the code exists. This loop builds test first, so it splits that job across three stages. Plan decides the tests, Build writes each one before the code, and Test checks them. So pass the skill the stage's inputs and overrides each time you invoke it.

## Plan decides the tests

Invoke it after you've read the spec, the RFC and the code the change touches.

| Input | What to pass |
|---|---|
| The change | The RFC's phases, and the files each phase touches |
| The spec | `spec.md`, and the RFC for an interface |

1. **The skill stops after its choice.** It classifies the change, and writes down the kind of test each component gets and the kinds it leaves out. It writes no test in this stage.
2. **The choice goes in `plan.md`.** Fill the plan's Tests section from it: the scenario, the playbook's "Done when" condition, one row per test, and the kinds left out. Each acceptance criterion maps to at least one row, and each phase takes its first failing test from the rows.
3. **Adopt and review modes compare.** Run the skill the same way, and give the approver each difference between its choice and the plan's tests.

## Build writes them first

Invoke it at each phase's test-first step.

| Input | What to pass |
|---|---|
| The change | The phase's section of `plan.md`, and the phase's rows in the Tests section |
| The spec | `spec.md`, and the RFC for an interface. Every expected value comes from them. |

1. **The plan already made the choice.** The skill skips its classification, takes the scenario and the kinds of test from the plan, and writes the phase's tests from the spec.
2. **The phase's order wins over the playbook's.** A new test fails at the test-first step, because the code doesn't exist yet. A test that pins current behaviour, such as one written before a refactor, passes at this point. After the phase's code passes, the skill finishes its checks on each test. Each one passes, gives the same result over five runs, and fails on a planted bug or a mutant.
3. **The phase writes the code.** The playbook's fix, change and refactor steps are the phase's own steps. A playbook step that acts on a running system, such as a canary or a chaos experiment, waits for Ship, and the report lists it as not run.
4. **A change to the tests is a departure from the plan.** When the skill's checks drop a planned test or call for another one, update the plan's Tests section in the same commit and say what changed.
5. **The report is a file.** Add the skill's report to `docs/sdlc/<slug>/testing/build.md`, under a heading for the phase.

## Test checks them

Invoke it at the stage's first step.

| Input | What to pass |
|---|---|
| The change | The branch's diff against the default branch |
| The spec | `spec.md`, and the Tests section of `plan.md` |

1. **The skill checks the tests Build wrote.** It runs the playbook's analysis steps on the diff, such as `test-quality-review` and `test-mutation`. Then it checks that the plan's "Done when" condition holds, and that every row in the Tests section has its test.
2. **It adds tests and changes no product code.** Let it write the tests that close a gap, and commit them on the feature branch.
3. **A test that fails on the code sends the feature back to Build.** The toolkit would keep such a test as an expected failure. Here it becomes a phase in `plan.md`.
4. **The report is a file.** Save it as `docs/sdlc/<slug>/testing/test.md`. Copy its "Not run" and "Unspecified" lists into the Gaps section of `verify.md`.

## When the toolkit isn't installed

The session lists `testing-toolkit:testing` among its skills when the toolkit is installed. Without it, Plan chooses the tests itself, Build writes each failing test itself, and Test skips the check. Record the stage's `testing` tool as skipped, with that reason, and tell the user that `sdlc:setup` installs it.
