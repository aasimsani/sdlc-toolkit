#!/usr/bin/env bash
# Fixture for the formal-check cases: a voucher service whose spec says that a voucher is never captured above its
# face value. A case's fixture.sh sources this file and calls one of
#   voucher_rfc_draft    the RFC is a draft whose capture step has a flaw, and no code exists yet
#   voucher_built        the RFC's fixed design was modelled and approved, and the code departs from it
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
F=docs/sdlc/voucher-holds

voucher_repo() {
  git init -q -b main .
  git config user.email dev@example.com
  git config user.name Dev
  mkdir -p vouchers tests docs/sdlc
  cat > CLAUDE.md <<'EOF'
# Voucher service
Python functions that the tills call to spend gift vouchers. Every till in a shop is its own process, and they share one SQLite file.

## Commands
- Verify: `python3 -m unittest discover -s tests`. Healthy output ends with `OK`.

## Conventions
- Amounts are whole pence, as integers.

## Things Claude gets wrong
EOF
  cat > REVIEW.md <<'EOF'
# Review rules
A finding must name a behaviour that breaks. Style taste never counts.
EOF
  : > vouchers/__init__.py
  cat > vouchers/store.py <<'EOF'
"""Voucher storage. Amounts are whole pence."""
import sqlite3


def connect(path=":memory:"):
    db = sqlite3.connect(path)
    db.execute("CREATE TABLE IF NOT EXISTS vouchers (code TEXT PRIMARY KEY, face_value INTEGER, available INTEGER)")
    return db


def issue(db, code, face_value):
    with db:
        db.execute("INSERT INTO vouchers VALUES (?, ?, ?)", (code, face_value, face_value))


def redeem(db, code, amount):
    """Deduct the amount at once. Returns False when the voucher has too little left."""
    with db:
        (available,) = db.execute("SELECT available FROM vouchers WHERE code = ?", (code,)).fetchone()
        if available < amount:
            return False
        db.execute("UPDATE vouchers SET available = available - ? WHERE code = ?", (amount, code))
        return True
EOF
  cat > tests/test_store.py <<'EOF'
import unittest

from vouchers import store


class RedeemTest(unittest.TestCase):
    def setUp(self):
        self.db = store.connect()
        store.issue(self.db, "GIFT-1", 5000)

    def test_redeem_deducts_the_amount(self):
        self.assertTrue(store.redeem(self.db, "GIFT-1", 2000))
        self.assertEqual(self.db.execute("SELECT available FROM vouchers").fetchone()[0], 3000)

    def test_redeem_above_the_available_value_is_refused(self):
        self.assertFalse(store.redeem(self.db, "GIFT-1", 6000))


if __name__ == "__main__":
    unittest.main()
EOF
  printf '__pycache__/\n' > .gitignore
  echo "Each subfolder holds one feature's artifacts and its sdlc.yaml." > docs/sdlc/README.md
  git add -A && git commit -q -m "base"
  git switch -q -c sam/voucher-holds
  mkdir -p "$F"
}

voucher_intent_and_spec() {
  cat > "$F/intent.md" <<'EOF'
# Holds on gift vouchers

## Problem
A till deducts a gift voucher the moment it is scanned. When the customer's card payment for the rest of the sale fails, staff refund the voucher by hand, and about one refund in twenty is forgotten.

## Proposed outcome
A till places a hold on the voucher's value, and captures it only when the sale completes. A hold that is never captured gives its value back without anyone acting.

## Success criteria
- No voucher refund is made by hand.
- No voucher is ever spent above its face value.

## Affected users and systems
- Shop staff at the tills
- `vouchers/store.py`

## Constraints
- Every till in a shop is its own process, and they share one SQLite file.

## Out of scope
- Vouchers that work across shops

## Open questions
- None
EOF
  cat > "$F/spec.md" <<'EOF'
# Holds on gift vouchers — spec

Risk: high
Policies applied: none

## Summary
A till reserves part of a voucher's value with a hold, captures the hold when the sale completes, and loses the hold when ten minutes pass without a capture.

## Requirements
- **R1** A till can place a hold for any amount up to the voucher's available value. The amount stops being available to other tills.
- **R2** A till captures its hold when the sale completes.
- **R3** A hold that isn't captured within ten minutes is released, and its amount becomes available again.
- **R4** The total captured against a voucher never exceeds its face value. This holds when two tills use the same voucher at once, and when a hold expires while its sale is still in progress.

## Non-functional requirements
- Placing a hold and capturing one each take under 50 ms on the shop's hardware.

## Acceptance criteria
| Id | Criterion | Covers |
|---|---|---|
| AC1 | A hold for 2,000 on a voucher with 5,000 available leaves 3,000 available. | R1 |
| AC2 | A hold above the available value is refused, and nothing changes. | R1 |
| AC3 | Capturing a hold adds its amount to the voucher's captured total. | R2 |
| AC4 | A hold that is ten minutes old is released by the next sweep, and its amount is available again. | R3 |
| AC5 | No order of holds, captures, expiries and sweeps by two tills takes the captured total above the face value. | R4 |

## Risks and policy concerns
| Concern | Policy owner | Resolution |
|---|---|---|
| Money: a voucher spent twice is a loss to the shop | Lee, tech lead | R4 and AC5 |

## Open questions
- None
EOF
}

# The RFC. $1 is the capture step, and $2 is the status line.
voucher_rfc() {
  cat > "$F/rfc.md" <<EOF
# RFC: Holds on gift vouchers

Status: $2

## Problem and goal
A till deducts a voucher at once, and a failed card payment then needs a refund by hand. The goal is a hold that a till captures when the sale completes, and that gives its value back when it isn't captured.

## Constraints
- Every till in a shop is its own process, and they share one SQLite file.
- A sale can take longer than ten minutes when the customer pays the rest by card.

## Options
| Option | Verdict |
|---|---|
| A. Hold, then capture, with a sweeper that releases expired holds | Chosen. |
| B. Deduct at once and refund by hand when the sale fails | Rejected. It is today's behaviour. |
| C. One long database transaction for each sale | Rejected. SQLite allows one writer, so one slow sale would block every till. |

## Chosen solution
Two tables hold the state. \`vouchers\` has \`code\`, \`face_value\`, \`available\` and \`captured\`. \`holds\` has \`id\`, \`code\`, \`amount\`, \`state\` and \`expires_at\`. A hold's state is \`live\`, \`captured\` or \`released\`.

1. **Hold.** In one transaction, the till reads the voucher's \`available\`. If it covers the amount, the till subtracts the amount from \`available\` and inserts a \`live\` hold that expires in ten minutes.
2. **Capture.** $1
3. **Sweeper.** A job runs every minute. For each \`live\` hold whose \`expires_at\` has passed, in one transaction, it adds the hold's amount back to the voucher's \`available\` and sets the hold's state to \`released\`.

Every hold reserves its amount before any capture, so the total captured against a voucher never exceeds its face value. This holds when two tills use the same voucher at once, and when a hold expires while its sale is still in progress.

## Fallback
If the sweeper causes lock contention, run it every five minutes.

## Phases and PRs
| Phase | PR | What it delivers |
|---|---|---|
| 1. Holds | PR 1 | The \`holds\` table, and the hold and capture functions |
| 2. Sweeper | PR 2 | The job that releases expired holds |

## Proposed tickets
- VCH-201: holds and capture
- VCH-202: sweeper

## Blast radius
| What could break | Detection | Rollback |
|---|---|---|
| A voucher is captured above its face value | The nightly comparison of \`captured\` with \`face_value\` | Turn holds off with the \`HOLDS_ENABLED\` flag |
EOF
}

# Writes sdlc.yaml. $1 is the last approved stage, and $2, when given, is a stage to leave as a draft.
voucher_state() {
  local upto="$1" draft="${2:-}" s day=1 tools
  {
    echo "feature: voucher-holds"
    echo "branch: sam/voucher-holds"
    echo "stages:"
    for s in intent spec rfc plan build; do
      day=$((day + 1)); tools=""
      if [ "$s" = rfc ]; then tools=', tools: {rfc-skill: "skipped: not installed", formal-verification: fv/design/README.md, goldfish: "skipped: EGM is not installed"}'; fi
      echo "  $s: {status: approved, owner: Sam, approver: Lee, approved_by: Lee, date: 2026-11-0$day, artifact: \"$( [ "$s" = build ] && echo "code on sam/voucher-holds" || echo "$s.md")\"$tools}"
      if [ "$s" = "$upto" ]; then break; fi
    done
    if [ -n "$draft" ]; then echo "  $draft: {status: draft, owner: Sam, approver: Lee, artifact: \"$draft.md\"}"; fi
  } > "$F/sdlc.yaml"
}

voucher_rfc_draft() {
  voucher_repo
  voucher_intent_and_spec
  voucher_rfc 'When the sale completes, in one transaction, the till sets its hold'"'"'s state to `captured` by the hold'"'"'s id and adds the hold'"'"'s amount to the voucher'"'"'s `captured`.' 'draft'
  voucher_state spec rfc
  git add -A && git commit -q -m "docs(sdlc): intent, spec and an RFC draft for voucher-holds"
  fv_jars
}

voucher_built() {
  voucher_repo
  voucher_intent_and_spec
  voucher_rfc 'When the sale completes, the till runs one conditional update that sets its hold'"'"'s state to `captured` only where the state is still `live`. It adds the hold'"'"'s amount to the voucher'"'"'s `captured` only when that update changed a row. When it changed none, the hold has expired, and the till asks the customer to pay another way.' 'approved by Lee on 2026-11-04'
  mkdir -p "$F/fv/design"
  cp "$LIB"/voucher-design/* "$F/fv/design/"
  cat > "$F/fv/design/README.md" <<'EOF'
# Voucher holds — the formal check of the design

The RFC stage checked the design in a TLA+ model before any code existed. Lee confirmed the properties on 2026-11-04.

## Property ledger
| Property | Source | Kind | Encoded as |
|---|---|---|---|
| The total captured against a voucher never exceeds its face value | "The total captured against a voucher never exceeds its face value" (spec, R4) | safety | `NeverOverCaptured` invariant |
| A hold really can be released, and its amount placed on hold again | unwritten; the safety property proves little without it | reachability | `WitnessReleased.cfg` must violate `NeverReleased` |

## Configs
| Config | Design | Declared outcome |
|---|---|---|
| `ConditionalCapture.cfg` | Capture changes nothing unless the hold is still live. This is the chosen design. | holds |
| `UncheckedCapture.cfg` | Capture updates the hold by its id, whatever state it is in. The RFC's first draft had this. | violated `NeverOverCaptured` |
| `WitnessReleased.cfg` | The chosen design | violated `NeverReleased` |

## Bounds, faults and what the model leaves out
- Two tills, one voucher, and holds for the full face value.
- A hold can expire at any moment after it is placed.
- The model has no clock, no crash and no retry.
- It describes the RFC's design. No code existed when it was written.

## Rerun
`fv-tlc VoucherHolds.tla`
EOF
  ( cd "$F/fv/design" && "$ROOT/.toolkits/fv-toolkit/scripts/fv-pin" write . VoucherHolds.tla:NeverOverCaptured ConditionalCapture.cfg UncheckedCapture.cfg WitnessReleased.cfg > /dev/null )
  cat > "$F/plan.md" <<'EOF'
# Holds on gift vouchers — plan

Verify command: `python3 -m unittest discover -s tests`

## Files to change
| File | Change |
|---|---|
| `vouchers/store.py` | The `holds` table, and `place_hold`, `capture` and `sweep` |
| `tests/test_store.py` | Tests for AC1 to AC5 |

## Phases
| # | Phase | Covers | Depends on | First failing test | Runs in | Status |
|---|---|---|---|---|---|---|
| 1 | Holds | AC1, AC2, AC3, AC5, PR 1 in the RFC | — | `tests/test_store.py::HoldTest::test_a_hold_reserves_its_amount` | main session | done |
| 2 | Sweeper | AC4, PR 2 in the RFC | 1 | `tests/test_store.py::SweepTest::test_an_expired_hold_is_released` | main session | done |

Status is `pending`, `in_progress` or `done`. One phase is in progress per session or worktree.

### Phase 1 — Holds
`connect` creates the `holds` table and adds `captured` to `vouchers`. `place_hold` reserves an amount in one transaction, and `capture` captures a hold.

### Phase 2 — Sweeper
`sweep` releases every live hold that has expired, and returns its amount.

## Todos
Only a phase that's in progress has todos here.

## Tests
Build writes each Build test before the code it tests. Test writes the final tests, which need the whole feature.

- Scenario: a new feature in existing code. Done when: every acceptance criterion has a test, and a test checks every changed line.
- Left out: load, because the 50 ms limit is checked by hand on the shop's hardware.

| Acceptance criterion | Test | Kind | Written in | Where the bug would be |
|---|---|---|---|---|
| AC1 | `HoldTest::test_a_hold_reserves_its_amount` | unit | Build, phase 1 | The arithmetic on `available` |
| AC2 | `HoldTest::test_a_hold_above_the_available_value_is_refused` | unit | Build, phase 1 | The comparison with `available` |
| AC3 | `HoldTest::test_capture_adds_to_the_captured_total` | unit | Build, phase 1 | The update of `captured` |
| AC4 | `SweepTest::test_an_expired_hold_is_released` | unit | Build, phase 2 | The expiry comparison |
| AC5 | `HoldTest::test_two_tills_cannot_hold_more_than_the_face_value` | unit | Build, phase 1 | Two holds that together exceed the face value |
EOF
  cat > vouchers/store.py <<'EOF'
"""Voucher storage. Amounts are whole pence, and times are seconds."""
import sqlite3

HOLD_SECONDS = 600


def connect(path=":memory:"):
    db = sqlite3.connect(path)
    db.execute(
        "CREATE TABLE IF NOT EXISTS vouchers "
        "(code TEXT PRIMARY KEY, face_value INTEGER, available INTEGER, captured INTEGER DEFAULT 0)"
    )
    db.execute(
        "CREATE TABLE IF NOT EXISTS holds "
        "(id INTEGER PRIMARY KEY, code TEXT, amount INTEGER, state TEXT, expires_at INTEGER)"
    )
    return db


def issue(db, code, face_value):
    with db:
        db.execute("INSERT INTO vouchers (code, face_value, available) VALUES (?, ?, ?)", (code, face_value, face_value))


def place_hold(db, code, amount, now):
    """Reserve an amount for ten minutes. Returns the hold's id, or None when too little is available."""
    with db:
        (available,) = db.execute("SELECT available FROM vouchers WHERE code = ?", (code,)).fetchone()
        if available < amount:
            return None
        db.execute("UPDATE vouchers SET available = available - ? WHERE code = ?", (amount, code))
        cur = db.execute(
            "INSERT INTO holds (code, amount, state, expires_at) VALUES (?, ?, 'live', ?)",
            (code, amount, now + HOLD_SECONDS),
        )
        return cur.lastrowid


def capture(db, hold_id):
    """Capture a hold when its sale completes. Returns True when the amount was captured."""
    with db:
        row = db.execute("SELECT code, amount FROM holds WHERE id = ?", (hold_id,)).fetchone()
        if row is None:
            return False
        code, amount = row
        db.execute("UPDATE holds SET state = 'captured' WHERE id = ?", (hold_id,))
        db.execute("UPDATE vouchers SET captured = captured + ? WHERE code = ?", (amount, code))
        return True


def sweep(db, now):
    """Release every live hold that has expired. Returns how many it released."""
    with db:
        expired = db.execute(
            "SELECT id, code, amount FROM holds WHERE state = 'live' AND expires_at <= ?", (now,)
        ).fetchall()
        for hold_id, code, amount in expired:
            db.execute("UPDATE vouchers SET available = available + ? WHERE code = ?", (amount, code))
            db.execute("UPDATE holds SET state = 'released' WHERE id = ?", (hold_id,))
        return len(expired)
EOF
  cat > tests/test_store.py <<'EOF'
import unittest

from vouchers import store


def voucher(db):
    return db.execute("SELECT available, captured FROM vouchers WHERE code = 'GIFT-1'").fetchone()


class HoldTest(unittest.TestCase):
    def setUp(self):
        self.db = store.connect()
        store.issue(self.db, "GIFT-1", 5000)

    def test_a_hold_reserves_its_amount(self):
        self.assertIsNotNone(store.place_hold(self.db, "GIFT-1", 2000, now=0))
        self.assertEqual(voucher(self.db), (3000, 0))

    def test_a_hold_above_the_available_value_is_refused(self):
        self.assertIsNone(store.place_hold(self.db, "GIFT-1", 6000, now=0))
        self.assertEqual(voucher(self.db), (5000, 0))

    def test_capture_adds_to_the_captured_total(self):
        hold = store.place_hold(self.db, "GIFT-1", 2000, now=0)
        self.assertTrue(store.capture(self.db, hold))
        self.assertEqual(voucher(self.db), (3000, 2000))

    def test_two_tills_cannot_hold_more_than_the_face_value(self):
        self.assertIsNotNone(store.place_hold(self.db, "GIFT-1", 5000, now=0))
        self.assertIsNone(store.place_hold(self.db, "GIFT-1", 5000, now=1))


class SweepTest(unittest.TestCase):
    def setUp(self):
        self.db = store.connect()
        store.issue(self.db, "GIFT-1", 5000)

    def test_an_expired_hold_is_released(self):
        store.place_hold(self.db, "GIFT-1", 2000, now=0)
        self.assertEqual(store.sweep(self.db, now=600), 1)
        self.assertEqual(voucher(self.db), (5000, 0))

    def test_a_hold_that_has_not_expired_stays(self):
        store.place_hold(self.db, "GIFT-1", 2000, now=0)
        self.assertEqual(store.sweep(self.db, now=599), 0)


if __name__ == "__main__":
    unittest.main()
EOF
  voucher_state build
  git add -A && git commit -q -m "feat: holds on gift vouchers, with the design's model and the plan"
  fv_jars
}
