# Decision Contracts Board (absorbs ChatGPT)

> Every decision is a contract with **an owner, a deadline, and a confidence value.**
> Solves the many-horses problem (exactly one owner per decision) + no-consensus (deadline forces convergence).

## Format
```
time [DECISION]
  proposal:   what to do (one line)
  owner:      who's responsible (exactly one bot/person)
  deadline:   complete by when
  confidence: 0.0–1.0 (Leader's confidence in this decision)
  basis:      which evidence/board entries it's based on (fingerprints)
  status:     OPEN | DONE | ESCALATED
```

## Rules
- **Exactly one owner**: no shared responsibility, avoids finger-pointing.
- confidence < `CONFIDENCE_ASK_CLOUD` (0.6) → `<ASK_CLOUD>` to verify before finalizing.
- Past deadline and not DONE → auto-ESCALATED to human (prevents infinite loops).
- Internal discussion reaches `DELIBERATION_MAX_PHASE` (3) with no consensus → Leader decides outright and logs a lower-confidence contract; **forbidden to blend into a Frankenstein.**

## Example
```
2026-06-01T09:20 [DECISION]
  proposal:   stagger the backup schedule to 04:00 to avoid I/O collision
  owner:      WorkerBot
  deadline:   2026-06-01T10:00
  confidence: 0.82
  basis:      iostat await=1200ms (evidence hash:ab12), VERIFY-BAGGING 2/3 passed
  status:     OPEN
```
