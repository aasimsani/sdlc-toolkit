#!/usr/bin/env bash
# Shared fixture for the stage cases. A case's fixture.sh sources this file and calls
#   seed <last approved stage> [stage to leave as a draft]
# It builds a small shell project and takes one feature, csv-export, as far through the loop as the case needs.
# Sam owns every stage and Lee approves it. Set BUGGY=1 to build the export without quoting for double quotes.
set -euo pipefail

F=docs/sdlc/csv-export

base() {
  git init -q -b main .
  git config user.email dev@example.com
  git config user.name Dev
  mkdir -p bin data tests docs/sdlc
  cat > CLAUDE.md <<'EOF'
# Reports service
Shell tools that the support and finance teams run to list invoices.

## Commands
- Verify: `sh verify.sh`. Healthy output ends with `N passed, 0 failed`.

## Conventions
- Amounts are decimal strings. Never parse them as floats.

## Things Claude gets wrong
EOF
  cat > REVIEW.md <<'EOF'
# Review rules
A finding must name a behaviour that breaks. Style taste never counts.
EOF
  cat > verify.sh <<'EOF'
#!/bin/sh
# Runs every tests/test_*.sh and prints "N passed, M failed". The last result is kept in .verify-last.
cd "$(dirname "$0")"
out="$(for t in tests/test_*.sh; do sh "$t"; done)"
echo "$out"
pass=$(echo "$out" | grep -c '^ok ')
fail=$(echo "$out" | grep -c '^FAIL ')
echo "$pass passed, $fail failed" | tee .verify-last
[ "$fail" = 0 ]
EOF
  printf '.verify-last\n.test-log\n' > .gitignore
  cat > tests/lib.sh <<'EOF'
# Shared by every tests/test_*.sh. A check prints "ok - name" or "FAIL - name", and appends the same line to .test-log.
check() {
  if eval "$2"; then r="ok - $1"; else r="FAIL - $1"; fi
  echo "$r"
  echo "$r" >> .test-log
}
EOF
  printf 'id\tcustomer\tamount\tstatus\nINV-001\tNorthwind Traders\t1200.00\topen\nINV-002\tAcme, Inc.\t310.50\tpaid\nINV-003\tGlobex\t89.99\topen\nINV-004\tInitech "West"\t4500.00\topen\n' > data/invoices.tsv
  cat > bin/invoices <<'EOF'
#!/bin/sh
# Usage: bin/invoices list [--status open|paid]
# Prints the invoice table from data/invoices.tsv, or from the file INVOICES_FILE names.
set -eu
root="$(cd "$(dirname "$0")/.." && pwd)"
data="${INVOICES_FILE:-$root/data/invoices.tsv}"
[ "${1:-}" = list ] || { echo "usage: invoices list [--status open|paid]" >&2; exit 2; }
shift
status=""
while [ $# -gt 0 ]; do
  case "$1" in
    --status) status="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
awk -F '\t' -v status="$status" '
  NR == 1 || status == "" || $4 == status { printf "%-8s %-22s %10s  %s\n", $1, $2, $3, $4 }
' "$data"
EOF
  chmod +x bin/invoices
  cat > tests/test_list.sh <<'EOF'
#!/bin/sh
# verify.sh counts the "ok" and "FAIL" lines that each check prints.
cd "$(dirname "$0")/.."
. tests/lib.sh
check "list prints the header and all four invoices" '[ "$(bin/invoices list | wc -l | tr -d " ")" = 5 ]'
check "--status open keeps the header and the three open invoices" '[ "$(bin/invoices list --status open | wc -l | tr -d " ")" = 4 ]'
check "an unknown option exits 2" 'bin/invoices list --nope >/dev/null 2>&1; [ $? = 2 ]'
EOF
  echo "Each subfolder holds one feature's artifacts and its sdlc.yaml." > docs/sdlc/README.md
  git add -A && git commit -q -m "base"
}

artifact_of() {
  case "$1" in
    (intent) echo intent.md ;; (spec) echo spec.md ;; (rfc) echo rfc.md ;; (plan) echo plan.md ;;
    (build) echo "code on sam/csv-export" ;; (test) echo verify.md ;; (ship) echo review.md ;;
    (adr) echo adr.md ;; (maintain) echo lessons.md ;;
  esac
}

# Writes sdlc.yaml with every stage up to $1 approved, and stage $2, when given, as a draft.
write_state() {
  local upto="$1" draft="${2:-}" s day=1
  {
    echo "feature: csv-export"
    echo "branch: sam/csv-export"
    echo "stages:"
    for s in intent spec rfc plan build test ship adr; do
      day=$((day + 1))
      echo "  $s: {status: approved, owner: Sam, approver: Lee, approved_by: Lee, date: 2026-11-0$day, artifact: \"$(artifact_of "$s")\"}"
      if [ "$s" = "$upto" ]; then break; fi
    done
    if [ -n "$draft" ]; then
      echo "  $draft: {status: draft, owner: Sam, approver: Lee, artifact: \"$(artifact_of "$draft")\"}"
    fi
  } > "$F/sdlc.yaml"
}

art_intent() {
  cat > "$F/intent.md" <<'EOF'
# CSV export for the invoice list

## Problem
Finance copies the output of `bin/invoices list` into a spreadsheet by hand every Monday. It takes about 20 minutes, and rows get missed.

## Proposed outcome
Finance runs one command and gets the listed invoices as CSV, ready to open in a spreadsheet.

## Success criteria
- Finance stops copying invoices by hand.
- An export of 2,000 invoices finishes in under 5 seconds.

## Affected users and systems
- The finance team
- `bin/invoices`

## Constraints
- No new dependencies. The service is POSIX shell and awk.

## Out of scope
- Scheduled exports
- Excel format

## Open questions
- None
EOF
}

art_spec() {
  cat > "$F/spec.md" <<'EOF'
# CSV export for the invoice list — spec

Risk: low
Policies applied: none

## Summary
`bin/invoices list` gains a `--csv` option that prints the listed invoices as CSV, so Finance can open them in a spreadsheet without copying by hand.

## Requirements
- **R1** `bin/invoices list --csv` prints a header row, `id,customer,amount,status`, and then one CSV row per listed invoice.
- **R2** `--csv` combines with `--status`, and exports only the invoices that filter lists.
- **R3** A field that contains a comma or a double quote is wrapped in double quotes, and each double quote inside it is doubled, as RFC 4180 describes.
- **R4** Without `--csv`, the output of `bin/invoices list` doesn't change.

## Non-functional requirements
- An export of 2,000 invoices finishes in under 5 seconds on a developer laptop.
- The change adds no dependency. The service stays POSIX shell and awk.

## Acceptance criteria
| Id | Criterion | Covers |
|---|---|---|
| AC1 | `bin/invoices list --csv` prints `id,customer,amount,status` and then four rows for the sample data. | R1 |
| AC2 | `bin/invoices list --status open --csv` prints the header and the three open invoices. | R2 |
| AC3 | The export has the rows `INV-002,"Acme, Inc.",310.50,paid` and `INV-004,"Initech ""West""",4500.00,open`. | R3 |
| AC4 | `bin/invoices list` prints the same bytes as it did before the change. | R4 |
| AC5 | With `INVOICES_FILE` pointing at a 2,000-invoice file, `bin/invoices list --csv` finishes in under 5 seconds. | Non-functional |

## Risks and policy concerns
| Concern | Policy owner | Resolution |
|---|---|---|
| None raised | | |

## Open questions
- None
EOF
}

art_rfc() {
  cat > "$F/rfc.md" <<'EOF'
# RFC: CSV export for the invoice list

Status: approved by Lee on 2026-11-04

## Problem and goal
Finance copies `bin/invoices list` output into a spreadsheet by hand. The goal is one command that prints the listed invoices as CSV.

## Constraints
- POSIX shell and awk only, with no new dependency.
- The table output must not change.

## Options
| Option | Verdict |
|---|---|
| A. Quote fields in a new `lib/csv.awk` file that `bin/invoices` loads with `awk -f` | Chosen. Other commands can reuse the quoting later. |
| B. Quote fields inline in the awk program inside `bin/invoices` | Rejected. It mixes the format with the listing. |
| C. Pipe the table through `sed` to swap spaces for commas | Rejected. It breaks on customer names that contain spaces or commas. |

## Chosen solution
`bin/invoices list --csv` runs the same filter as the table, and prints each row through a `csv_field` function that lives in a new file, `lib/csv.awk`. The function wraps a field in double quotes when it contains a comma or a double quote, and doubles each inner quote.

## Fallback
If `awk -f` with two program files behaves differently on the CI image, move the function inline (option B).

## Phases and PRs
| Phase | PR | What it delivers |
|---|---|---|
| 1. CSV output | PR 1 | `--csv` prints the header and the rows, with no quoting yet |
| 2. Quoting | PR 2 | `lib/csv.awk` and the `csv_field` function |

## Proposed tickets
- REP-101: `--csv` output
- REP-102: CSV quoting

## Blast radius
| What could break | Detection | Rollback |
|---|---|---|
| The table output changes | `tests/test_list.sh` | Revert the PR |
EOF
}

art_plan() {
  cat > "$F/plan.md" <<'EOF'
# CSV export for the invoice list — plan

Verify command: `sh verify.sh`

## Files to change
| File | Change |
|---|---|
| `bin/invoices` | Parse `--csv`, and print the listed rows as CSV |
| `lib/csv.awk` | New file with the `csv_field` quoting function |
| `tests/test_csv.sh` | New test file for AC1, AC2, AC3 and AC5, using `check` from `tests/lib.sh` |

## Phases
| # | Phase | Covers | Depends on | First failing test | Runs in | Status |
|---|---|---|---|---|---|---|
| 1 | CSV output | AC1, AC2, AC4, PR 1 in the RFC | — | `tests/test_csv.sh` "list --csv prints the header and four rows" | main session | in_progress |
| 2 | Quoting | AC3, AC5, PR 2 in the RFC | 1 | `tests/test_csv.sh` "a customer with a comma is quoted" | main session | pending |

Status is `pending`, `in_progress` or `done`. One phase is in progress per session or worktree.

### Phase 1 — CSV output
`bin/invoices list` accepts `--csv` in its option loop. With the flag set, the awk program prints the header and each listed row with commas between the four fields, and without any quoting. `--status` filters the rows the same way for both formats. The table output stays as it is, and `tests/test_list.sh` proves that.

### Phase 2 — Quoting
A `csv_field` function in `lib/csv.awk` wraps a field in double quotes when it has a comma or a double quote, and doubles each inner quote. `bin/invoices` loads the file with `awk -f` and prints every field through the function. A test builds a 2,000-invoice file, points `INVOICES_FILE` at it, and checks that the export finishes in under 5 seconds.

## Todos
Only a phase that's in progress has todos here. Build writes the next phase's todos when it starts that phase.

### Phase 1 — CSV output
- [ ] Write the failing test "list --csv prints the header and four rows" in `tests/test_csv.sh` and watch it fail
- [ ] Write the failing test "--status open --csv keeps the header and the three open invoices"
- [ ] Add `--csv` to `bin/invoices` until both tests pass
- [ ] Run `sh verify.sh`, and run pr-review

## Tests
| Acceptance criterion | Test |
|---|---|
| AC1 | `tests/test_csv.sh` "list --csv prints the header and four rows" |
| AC2 | `tests/test_csv.sh` "--status open --csv keeps the header and the three open invoices" |
| AC3 | `tests/test_csv.sh` "a customer with a comma is quoted" and "a customer with a double quote is quoted" |
| AC4 | `tests/test_list.sh`, all three checks |
| AC5 | `tests/test_csv.sh` "2,000 invoices export in under 5 seconds" |
EOF
}

# Writes the finished code. The quoting sits inline in bin/invoices, which departs from the RFC's lib/csv.awk.
art_build() {
  local quote_rule='if ($i ~ /[",]/) { gsub(/"/, "\"\"", $i); $i = "\"" $i "\"" }'
  if [ "${BUGGY:-0}" = 1 ]; then quote_rule='if ($i ~ /,/) $i = "\"" $i "\""'; fi
  cat > bin/invoices <<EOF
#!/bin/sh
# Usage: bin/invoices list [--status open|paid] [--csv]
# Prints the invoice table from data/invoices.tsv, or from the file INVOICES_FILE names.
set -eu
root="\$(cd "\$(dirname "\$0")/.." && pwd)"
data="\${INVOICES_FILE:-\$root/data/invoices.tsv}"
[ "\${1:-}" = list ] || { echo "usage: invoices list [--status open|paid] [--csv]" >&2; exit 2; }
shift
status=""
csv=0
while [ \$# -gt 0 ]; do
  case "\$1" in
    --status) status="\$2"; shift 2 ;;
    --csv) csv=1; shift ;;
    *) echo "unknown option: \$1" >&2; exit 2 ;;
  esac
done
if [ "\$csv" = 1 ]; then
  awk -F '\t' -v status="\$status" '
    NR == 1 || status == "" || \$4 == status {
      for (i = 1; i <= NF; i++) $quote_rule
      print \$1 "," \$2 "," \$3 "," \$4
    }
  ' "\$data"
else
  awk -F '\t' -v status="\$status" '
    NR == 1 || status == "" || \$4 == status { printf "%-8s %-22s %10s  %s\n", \$1, \$2, \$3, \$4 }
  ' "\$data"
fi
EOF
  cat > tests/test_csv.sh <<'EOF'
#!/bin/sh
cd "$(dirname "$0")/.."
. tests/lib.sh
check "list --csv prints the header and four rows" '[ "$(bin/invoices list --csv | head -1)" = "id,customer,amount,status" ] && [ "$(bin/invoices list --csv | wc -l | tr -d " ")" = 5 ]'
check "--status open --csv keeps the header and the three open invoices" '[ "$(bin/invoices list --status open --csv | wc -l | tr -d " ")" = 4 ]'
check "a customer with a comma is quoted" 'bin/invoices list --csv | grep -qxF "INV-002,\"Acme, Inc.\",310.50,paid"'
EOF
  if [ "${BUGGY:-0}" != 1 ]; then
    cat >> tests/test_csv.sh <<'EOF'
check "a customer with a double quote is quoted" 'bin/invoices list --csv | grep -qxF "INV-004,\"Initech \"\"West\"\"\",4500.00,open"'
EOF
  fi
  sed -e 's/| in_progress |$/| done |/' -e 's/| pending |$/| done |/' -e 's/^- \[ \]/- [x]/' "$F/plan.md" > "$F/plan.tmp"
  awk '
    /^## Tests/ {
      print "### Phase 2 — Quoting"
      print "- [x] Write the failing test \"a customer with a comma is quoted\" and watch it fail"
      print "- [x] Add the quoting until the test passes"
      print "- [x] Run `sh verify.sh`, and run pr-review"
      print ""
      print "## Departures from the plan"
      print "- Phase 2 put the quoting inline in the awk program in `bin/invoices`. The plan and the RFC put it in a new file, `lib/csv.awk`. The pr-review run for Build flagged the separate file as a cut worth making, because the function has one caller, and Lee agreed on 2026-11-06."
      print "- Both phases went into one PR. The RFC proposed two."
      print ""
    }
    { print }
  ' "$F/plan.tmp" > "$F/plan.md"
  rm "$F/plan.tmp"
}

art_test() {
  cat > "$F/verify.md" <<'EOF'
# CSV export for the invoice list — verification

## Verify command
`sh verify.sh`

```
ok - a customer with a comma is quoted
ok - a customer with a double quote is quoted
7 passed, 0 failed
```

## Acceptance criteria
| Id | Evidence | Result |
|---|---|---|
| AC1 | `tests/test_csv.sh` "list --csv prints the header and four rows" passes | pass |
| AC2 | `tests/test_csv.sh` "--status open --csv keeps the header and the three open invoices" passes | pass |
| AC3 | Both quoting checks pass, and the verifier saw `INV-004,"Initech ""West""",4500.00,open` | pass |
| AC4 | `tests/test_list.sh` passes, and the table output matches the base branch byte for byte | pass |
| AC5 | The verifier exported a 2,000-invoice file in 0.4 seconds | pass |

## Gaps
- Nothing checks an export larger than 2,000 invoices.
EOF
}

art_ship() {
  cat > "$F/review.md" <<'EOF'
# CSV export for the invoice list — review

PR: https://github.com/example/reports/pull/42
Approved and merged by: Lee, on 2026-11-08

## Findings
| Fingerprint | Severity | Finding | Disposition |
|---|---|---|---|
| `PERF\|bin/invoices\|csv\|one awk process per call` | Low | The export reads the whole file in one awk process. | won't fix — it's fast enough at 2,000 invoices |

## Deploy
1. Merge PR 42. The finance team pulls `main` on Monday.

## Rollback
1. Revert the merge commit of PR 42.
EOF
}

art_adr() {
  cat > "$F/adr.md" <<'EOF'
# ADR: The invoice list exports CSV with quoting inline in bin/invoices

Status: Accepted on 2026-11-08, PR https://github.com/example/reports/pull/42, approved by Lee

## Decision
`bin/invoices list --csv` prints the listed invoices as CSV. The quoting sits inline in the awk program in `bin/invoices`.

## As built
- One PR, number 42, delivered both phases. The RFC proposed two.
- The RFC put the quoting in `lib/csv.awk`. It shipped inline, because the function has one caller.

## Consequences
| What could break | Detection | Rollback |
|---|---|---|
| The table output changes | `tests/test_list.sh` | Revert PR 42 |
EOF
}

seed() {
  local upto="$1" draft="${2:-}" s
  base
  git switch -q -c sam/csv-export
  mkdir -p "$F"
  for s in intent spec rfc plan build test ship adr; do
    "art_$s"
    write_state "$s"
    git add -A && git commit -q -m "docs(sdlc): $s for csv-export"
    if [ "$s" = "$upto" ]; then break; fi
  done
  if [ -n "$draft" ]; then
    write_state "$upto" "$draft"
    git add -A && git commit -q -m "docs(sdlc): start $draft for csv-export"
  fi
}
