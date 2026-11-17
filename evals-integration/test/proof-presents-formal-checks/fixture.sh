#!/usr/bin/env bash
# Seeds the empty workspace for this case. `claude plugin eval --scaffold` runs it.
# The design was modelled at RFC, and the second model's report is already on the branch, so the case starts
# where the Prove half presents the formal checks.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../_lib/voucher.sh"
voucher_built
cat > "$F/fv/code-report.md" <<'EOF'
# Formal check of voucher holds: the code, against the confirmed properties

Scope: `vouchers/store.py` as changed on `sam/voucher-holds` against `main`. The model, its configs and its mutations file are in `docs/sdlc/voucher-holds/fv/code/`. This check read `spec.md` and the code, and nothing else in the feature folder.

## Finding 1: capturing a hold that isn't live adds its amount again

`capture()` checks only that the hold's row exists. It never reads the hold's state.

1. A voucher is issued with a face value of 5000.
2. Till A places a hold for 5000. The voucher has 0 available, and the hold is live.
3. The hold passes its ten minutes while till A's sale is still running, and the sweep releases it. The voucher has 5000 available again.
4. Till B places a hold for 5000 and captures it. Captured is 5000.
5. Till A's sale completes and captures its released hold. `capture()` returns True, and captured is 10000 on a face value of 5000.

Disposition: reproduced against the real code with `store.place_hold`, `store.sweep` and `store.capture`. The same call, made twice on one live hold, also doubles the captured total.

## Property ledger

| Claim | Check | Bounds and faults | Verdict | Mutations | Link to code |
|---|---|---|---|---|---|
| The total captured against a voucher never exceeds its face value (spec R4) | TLA+ with TLC, `NeverOverCaptured` in `VoucherStore.tla` | 2 tills, up to 3 hold ids, 1 voucher. A hold can expire at any point. No crash, and no two sweeps at once. | Fails on the code as shipped (`ShippedCode.cfg`). `FixedCapture.cfg`, with the state check added, holds within the same bounds. | 3 of 3 detected | No test. `test_capture_adds_to_the_captured_total` calls `capture` once. |
| A hold can be released and its amount placed on hold again | TLC witness, `WitnessReleaseAndRehold.cfg` | 1 till, 2 hold ids | Reachable | not applicable | `test_an_expired_hold_is_released` covers the release |

## What this check leaves open
- Sizes: two tills and three holds. Larger runs were not tried.
- The ten-minute deadline is one abstract event. The arithmetic on seconds was not checked.
- Two sweeps that run at once were not modelled.

## Rerun
```bash
cd docs/sdlc/voucher-holds/fv/code
fv-tlc VoucherStore.tla
fv-mutate VoucherStore.mutations
fv-pin check .
```
EOF
git add -A && git commit -q -m "test(fv): the second model's report for voucher-holds"
