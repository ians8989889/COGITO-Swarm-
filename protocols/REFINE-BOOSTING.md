# 🔁 REFINE-BOOSTING — Sequential Refinement Chain (reduce bias / fill systematic gaps)

> For refinable "is this good enough" questions. Runs **sequentially**, each leg fixes the previous leg's weaknesses.
> What it kills is **systematic bias**: a single pass always has structural misses, filled in by stepwise approximation.
> This is the real Boosting (the old version wrongly called voting by this name).

---

## When to use (route = `boost`)

- Architecture/design decisions, long-form, complex analysis, output that needs multi-step reasoning to do well
- Scenarios where one pass is definitely not good enough and the error is "missed/shallow" rather than "fabricated"
- Can be capped with a Bagging vote afterward (`boost_then_bag`)

---

## Flow (each leg targets the previous leg's residual)

```
Round 1  Leader drafts draft₀
        ▼
       Critic targets weaknesses: "missed X, argument Y too weak, edge case Z unhandled"
        ▼
Round 2  Leader revises → draft₁ (only the residuals pointed out)
        ▼
       Critic picks again (remaining weaknesses)
        ▼
   Convergence test: this round has almost no new weaknesses / reached CONVENE_MAX_ROUNDS → stop
```

- The Critic can be the Advisor, or spawn an external model as a dedicated nitpicker.
- **Can early-stop:** if round 1's critique already has no substantive weakness, stop immediately (this is where Boosting saves over Bagging).

## §Anti-drift (Boosting's vital weakness)

A sequential chain **propagates errors down the chain** and may **overfit to one critic's preferences**, drifting further from the original requirement with each revision. Countermeasures:

1. **Check against the original spec / definition-of-done each round**, not against the previous draft. The Critic's instruction must carry the original task and ask "what's still missing relative to the **original goal**," not "what else could be changed" (the latter never ends).
2. **Bound the rounds** (`CONVENE_MAX_ROUNDS`, default 2).
3. **Change only the named residuals**, don't casually rewrite already-passed parts (avoids introducing new errors).
4. The Critic and Reviser should ideally be different models / different perspectives, to avoid self-confirmation.

## Instruction template for the Critic

```
"This is the [original task goal]: <spec>.
 This is the current draft: <draftₙ>.
 List at most 3 concrete gaps + fixes, only where it is 'still missing/weak relative to the original goal.'
 If it sufficiently meets the goal, reply 'NO_SIGNIFICANT_GAP' (triggers early-stop)."
```

## Relation to the single integrator (anti-Frankenstein)
Boosting is **the same author (Leader) repeatedly refining its own draft**, not stitching together fragments from many. Single authorship → coherent product, won't become a Frankenstein.

## Cost
Can early-stop, mostly 1–2 LLM calls. Cheaper than Bagging's fixed N×, suitable for token-sensitive scenarios.
