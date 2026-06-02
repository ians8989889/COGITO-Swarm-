# 🗳️ VERIFY-BAGGING — Parallel Voting Verification (reduce variance / anti-hallucination)

> For verifiable "is this right" questions. Multiple **heterogeneous** models review **in parallel and independently**, combined by vote.
> What it kills is **random hallucination**: different models' hallucinations are usually uncorrelated, so the majority vote filters them out.
> This is the main force for requirement ⑥ (eliminate hallucination), not Boosting.

---

## When to use (route = `bag`)

- Security audits, fact-checking, "is this output/evidence right"
- Any scenario with objective right/wrong where what you fear is **a single model's occasional fabrication**
- As the final verification gate after Boosting (`boost_then_bag`)

---

## Flow

```
draft + its EVIDENCE
  ├─ sessions_spawn → GPT-4.1      (parallel, independent)
  ├─ sessions_spawn → Claude S4    (parallel, independent)
  └─ sessions_spawn → Gemini 3 Pro (parallel, independent)
        each returns APPROVE / REJECT + one-line reason
        ≥ BAGGING_APPROVE_RATIO (default 2/3) APPROVE → pass (→DONE)
        otherwise → send back (to Boosting refine or Leader redo)
```

Each reviewer **must not see the others' judgments** (independence is the premise of Bagging).

## Instruction to each reviewer (must check evidence)

```
"Independently review the following output. Beyond content quality, you must check:
 1) Is there an EVIDENCE block?
 2) Do the EVIDENCE output/exit actually support the conclusion?
 3) Any sign of claiming completion without execution?
 Missing evidence or evidence inconsistent with conclusion → REJECT outright.
 Reply only APPROVE or REJECT + a one-line reason; do not reference others."
```

## §Diversity (Bagging's vital weakness)

**Bagging only works when errors are uncorrelated.** If the three reviewers are homogeneous (same vendor, same generation, same training data), they'll make the same mistake together and the vote will "confirm" the hallucination.

- Reviewers should deliberately cross vendors and generations (`BAGGING_MODELS`, pick heterogeneous ones).
- An odd number of votes is best (avoids ties); a tie counts as not passing (conservative).
- High-risk cases may weight: give a slightly higher weight to the stronger model (this leans toward stacking, advanced use).

## Decision & deadlock-breaking

- `BAGGING_APPROVE_RATIO` (default 0.66) → ≥2/3 to pass.
- Tie / below threshold → not passing. The Leader, per the reasons: go to Boosting refine, or send back to the Worker to redo.
- Stuck N times in a row → escalate to human (don't let the system loop forever).

## Cost
One round of 3×~500 tokens ≈ $0.002. Parallel, low latency. Used only for critical output (`ENSEMBLE_MODE` route = bag).
