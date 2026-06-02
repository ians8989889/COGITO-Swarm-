# 🎛️ ENSEMBLE — Ensemble Routing (Bagging / Boosting / Both)

> v1.1 correction: the old version called "3-model voting" Boosting, **but that's actually Bagging.**
> Naming the mechanism wrong leads to picking the wrong tool. This page is the router; it decides which path by task type, with details on their own pages:
> - Parallel voting verification (reduce variance / anti-hallucination) → `protocols/VERIFY-BAGGING.md`
> - Sequential refinement (reduce bias / fill systematic gaps) → `protocols/REFINE-BOOSTING.md`

---

## The difference in one line

| | Bagging | Boosting |
|---|---|---|
| Structure | parallel, independent | sequential, each fixes the previous |
| Combine | vote / average | weighted sum (stepwise approximation) |
| Kills | **variance**: random errors, hallucination | **bias**: systematic misses, hard cases done wrong |
| Cost | fixed N×, fast | can early-stop, sequential, slow |
| Used for | verifiable "is this right" questions | refinable "is this good enough" questions |

Synthesis mnemonic: **"Boost to build, Bag to verify"** — refine a hard output with Boosting to raise quality, then use Bagging to block hallucination.

---

## Auto-routing (decided by `scripts/ensemble_route.sh`, $0)

`ENSEMBLE_MODE` in `config.env` defaults to `auto`. The Leader sets four cheap flags for each critical output, and the router outputs a mode:

| Task feature | Route | Why |
|---|---|---|
| Routine / internal status | `skip` | cost > benefit |
| Has right/wrong, guard random hallucination (fact-check/safety/facts) | `bag` | independent models' hallucinations are uncorrelated, voting cancels them |
| Hard, needs stepwise refinement (design/long-form/complex analysis) | `boost` | fills systematic gaps, can early-stop |
| Hard AND critical AND must be correct (architecture decision + external) | `boost_then_bag` | refine to raise quality first, then vote to guard hallucination |

Flags: `task_class` (routine/verify/generate/critical), `is_verifiable`, `is_hard`, `is_critical`.

```
ensemble_route.sh <task_class> <is_verifiable 0|1> <is_hard 0|1> <is_critical 0|1>
  → prints skip | bag | boost | boost_then_bag
```

`ENSEMBLE_MODE` can also be hard-set (`bag`/`boost`/`boost_then_bag`/`off`) to override auto.

---

## Two traps you must remember

1. **Bagging only works when errors are uncorrelated.** Reviewers must be deliberately **heterogeneous** (different vendors/generations); homogeneous models will vote wrong together and "confirm" the hallucination. See `VERIFY-BAGGING.md §Diversity`.
2. **Boosting propagates errors down the chain and may overfit to one critic.** Bound the rounds + check against the original spec each round so it doesn't drift further. See `REFINE-BOOSTING.md §Anti-drift`.

---

## Cost & minimal tokens (requirement ③)

| Task importance | Route | Approx cost |
|---|---|---|
| Routine/internal | skip | $0 |
| Medium | boost (early-stop, most pass on the first draft) | ~1–2 LLM calls |
| Critical-verifiable | bag (3 heterogeneous models in parallel) | 3×~500 tok ≈ $0.002 |
| Critical-and-hard | boost_then_bag | sum of the above |

> Routing itself is $0 (local shell). Only the chosen path actually costs money, and routine tasks always skip.
