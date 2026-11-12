# Running the testing toolkit

The [testing toolkit](https://github.com/aasimsani/testing-toolkit) decides which kinds of test a change needs and writes them from the spec. Its `testing` skill classifies the change, picks a kind of test for each component and calls the toolkit's other skills in order. Invoke `testing-toolkit:testing` with the Skill tool, and let it choose the other skills. `sdlc:setup` installs it.

The skill expects the code to exist and the user to judge its report. In this loop the test comes before the code, and a gate follows. So pass it the stage's inputs and overrides each time you invoke it.

## Build, once per phase

Invoke it at the phase's test-first step.

| Input | What to pass |
|---|---|
| The change | The phase's section of `plan.md`, and the acceptance criteria the phase covers |
| The spec | `spec.md`, and the RFC for an interface. Every expected value comes from them. |

1. **The phase's order wins over the playbook's.** At the test-first step, the skill classifies the phase, writes down which kind of test each component gets, and writes the tests from the spec. A new test fails at this point, because the code doesn't exist yet. A test that pins current behaviour, such as one written before a refactor, passes at this point. After the phase's code passes, the skill finishes its checks on each test. Each one passes, gives the same result over five runs, and fails on a planted bug or a mutant.
2. **The phase writes the code.** The playbook's fix, change and refactor steps are the phase's own steps. A playbook step that acts on a running system, such as a canary or a chaos experiment, waits for Ship, and the report lists it as not run.
3. **`plan.md` stays true.** Every test the plan names gets written. When the skill adds a test, or picks another kind of test for a criterion, update the plan's Tests table in the same commit.
4. **The report is a file.** Add the skill's report to `docs/sdlc/<slug>/testing/build.md`, under a heading for the phase.

## Test, once for the branch

Invoke it at the stage's first step.

| Input | What to pass |
|---|---|
| The change | The branch's diff against the default branch |
| The spec | `spec.md`, and the Tests table in `plan.md` |

1. **The skill checks the tests Build wrote.** It classifies the feature and runs the playbook's analysis steps on the diff, such as `test-quality-review` and `test-mutation`. Then it compares the result with the playbook's "Done when" column, and checks that every acceptance criterion has a test.
2. **It adds tests and changes no product code.** Let it write the tests that close a gap, and commit them on the feature branch.
3. **A test that fails on the code sends the feature back to Build.** The toolkit would keep such a test as an expected failure. Here it becomes a phase in `plan.md`.
4. **The report is a file.** Save it as `docs/sdlc/<slug>/testing/test.md`. Copy its "Not run" and "Unspecified" lists into the Gaps section of `verify.md`.

## When the toolkit isn't installed

The session lists `testing-toolkit:testing` among its skills when the toolkit is installed. Without it, Build writes each failing test itself, and Test skips the step. Record the stage's `testing` tool as skipped, with that reason, and tell the user that `sdlc:setup` installs it.
