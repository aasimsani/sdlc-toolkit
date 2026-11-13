---------------------------- MODULE VoucherHolds ----------------------------
(* The design in docs/sdlc/voucher-holds/rfc.md, before any code exists.
   Each action names the RFC step it transcribes.

   One voucher has a face value. A till places a hold, which reserves an
   amount. The till captures the hold when its sale completes. A sweeper
   releases a hold that has expired, and returns its amount.

   The knob CaptureChecksLive chooses the design:
     TRUE   capture is one conditional update, and it changes nothing when
            the hold is no longer live
     FALSE  capture updates the hold by its id, whatever state it is in

   The model leaves out the clock. A hold expires at any moment after it is
   placed, which covers every timing of the ten-minute limit. It also gives
   each till one hold, and every hold the same amount. *)
EXTENDS Naturals

CONSTANTS Tills, Face, Amount, CaptureChecksLive

VARIABLES available, hold, expired, captured

vars == <<available, hold, expired, captured>>

HoldStates == {"none", "live", "captured", "released"}

TypeOK ==
    /\ available \in 0..(2 * Face)
    /\ hold \in [Tills -> HoldStates]
    /\ expired \in [Tills -> BOOLEAN]
    /\ captured \in 0..(2 * Face)

Init ==
    /\ available = Face
    /\ hold = [t \in Tills |-> "none"]
    /\ expired = [t \in Tills |-> FALSE]
    /\ captured = 0

\* RFC "Hold": one transaction checks the available value and reserves it.
PlaceHold(t) ==
    /\ hold[t] = "none"
    /\ available >= Amount
    /\ available' = available - Amount
    /\ hold' = [hold EXCEPT ![t] = "live"]
    /\ UNCHANGED <<expired, captured>>

\* The ten minutes pass while the sale is still in progress.
Expire(t) ==
    /\ hold[t] = "live"
    /\ ~expired[t]
    /\ expired' = [expired EXCEPT ![t] = TRUE]
    /\ UNCHANGED <<available, hold, captured>>

\* RFC "Sweeper": one transaction returns the amount and marks the hold released.
Sweep(t) ==
    /\ hold[t] = "live"
    /\ expired[t]
    /\ available' = available + Amount
    /\ hold' = [hold EXCEPT ![t] = "released"]
    /\ UNCHANGED <<expired, captured>>

\* RFC "Capture": the till captures the hold it placed.
Capture(t) ==
    /\ IF CaptureChecksLive
          THEN hold[t] = "live"
          ELSE hold[t] \in {"live", "released"}
    /\ hold' = [hold EXCEPT ![t] = "captured"]
    /\ captured' = captured + Amount
    /\ UNCHANGED <<available, expired>>

Next == \E t \in Tills : PlaceHold(t) \/ Expire(t) \/ Sweep(t) \/ Capture(t)

Spec == Init /\ [][Next]_vars

\* The total captured against a voucher never exceeds its face value.
NeverOverCaptured == captured <= Face

\* Used by the witness config only: it must be violated, which shows that a
\* hold really can be released and its amount placed on hold again.
NeverReleased == \A t \in Tills : hold[t] # "released"
=============================================================================
