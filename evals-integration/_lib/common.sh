#!/usr/bin/env bash
# Shared by the integration cases. A case's fixture.sh sources this file.
# It builds on the stage fixture in plugins/sdlc/evals/_lib/lifecycle.sh and adds three things:
# a plan whose Tests section sorts each test into Build or Test, two weak tests for the audit to find,
# and the model checkers' jars.
set -euo pipefail
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$LIB/../.." && pwd)"
. "$ROOT/plugins/sdlc/evals/_lib/lifecycle.sh"

# The run's HOME is a temporary directory. The sandbox can't read the real one, and it can't download anything.
fv_jars() {
  local real; real="$(eval echo "~$(id -un)")"
  mkdir -p "$HOME/.cache/fv"
  cp "$real"/.cache/fv/*.jar "$HOME/.cache/fv/" 2>/dev/null || "$ROOT/.toolkits/fv-toolkit/scripts/fv-install" > /dev/null
}

# Replaces lifecycle.sh's plan with one in the shape the Plan stage writes now. seed calls it by name.
# The 2,000-invoice timing is a final test, so Build must leave it alone and Test must write it.
art_plan() {
  cat > "$F/plan.md" <<'PLAN'
# CSV export for the invoice list — plan

Verify command: `sh verify.sh`

## Files to change
| File | Change |
|---|---|
| `bin/invoices` | Parse `--csv`, and print the listed rows as CSV |
| `lib/csv.awk` | New file with the `csv_field` quoting function |
| `tests/test_csv.sh` | New test file for AC1, AC2 and AC3, using `check` from `tests/lib.sh` |
| `tests/final/test_perf.sh` | New final test for AC5. The Test stage writes it. |

## Phases
| # | Phase | Covers | Depends on | First failing test | Runs in | Status |
|---|---|---|---|---|---|---|
| 1 | CSV output | AC1, AC2, AC4, PR 1 in the RFC | — | `tests/test_csv.sh` "list --csv prints the header and four rows" | main session | in_progress |
| 2 | Quoting | AC3, PR 2 in the RFC | 1 | `tests/test_csv.sh` "a customer with a comma is quoted" | main session | pending |

Status is `pending`, `in_progress` or `done`. One phase is in progress per session or worktree.

### Phase 1 — CSV output
`bin/invoices list` accepts `--csv` in its option loop. With the flag set, the awk program prints the header and each listed row with commas between the four fields, and without any quoting. `--status` filters the rows the same way for both formats. The table output stays as it is, and `tests/test_list.sh` proves that.

### Phase 2 — Quoting
A `csv_field` function in `lib/csv.awk` wraps a field in double quotes when it has a comma or a double quote, and doubles each inner quote. `bin/invoices` loads the file with `awk -f` and prints every field through the function.

## Todos
Only a phase that's in progress has todos here. Build writes the next phase's todos when it starts that phase.

### Phase 1 — CSV output
- [ ] Write the failing test "list --csv prints the header and four rows" in `tests/test_csv.sh` and watch it fail
- [ ] Write the failing test "--status open --csv keeps the header and the three open invoices"
- [ ] Add `--csv` to `bin/invoices` until both tests pass
- [ ] Run `sh verify.sh`, and run pr-review

## Tests
Build writes each Build test before the code it tests. Test writes the final tests, which need the whole feature.

- Scenario: a new feature in existing code. Done when: every acceptance criterion has a test, and a test checks every changed line.
- Left out: end-to-end, because the tool has one command and no journey. Integration, because the tool reads one local file and crosses no service or database boundary.

| Acceptance criterion | Test | Kind | Written in | Where the bug would be |
|---|---|---|---|---|
| AC1 | `tests/test_csv.sh` "list --csv prints the header and four rows" | unit | Build, phase 1 | The option loop and the row printer |
| AC2 | `tests/test_csv.sh` "--status open --csv keeps the header and the three open invoices" | unit | Build, phase 1 | The filter that the table output shares |
| AC3 | `tests/test_csv.sh` "a customer with a comma is quoted" and "a customer with a double quote is quoted" | unit | Build, phase 2 | The quoting rule for commas and double quotes |
| AC4 | `tests/test_list.sh`, all three checks | characterization | Build, phase 1 | The table output, which must not change |
| AC5 | `tests/final/test_perf.sh` "2,000 invoices export in under 5 seconds" | load | Test | The awk pass over a large file |
PLAN
}

# The toolkit clears stray files after it plants a bug, so the check log moves to a place a cleanup doesn't reach.
log_under_git() {
  cat > tests/lib.sh <<'LIBSH'
# Shared by every tests/test_*.sh. A check prints "ok - name" or "FAIL - name", and logs the same line under .git/.
check() {
  if eval "$2"; then r="ok - $1"; else r="FAIL - $1"; fi
  echo "$r"
  { echo "$r" >> .git/test-log; } 2>/dev/null || true
}
LIBSH
  git add -A && git commit -q -m "test: keep the check log out of the working tree"
}

# Two tests that earn no place. One always passes, because its last command is `true`. One repeats a count that another test makes.
weak_tests() {
  cat >> tests/test_csv.sh <<'WEAK'
check "export never crashes" 'bin/invoices list --csv >/dev/null 2>&1; true'
check "csv output has five lines" '[ "$(bin/invoices list --csv | wc -l | tr -d " ")" = 5 ]'
WEAK
  git add -A && git commit -q -m "test: more csv checks"
}
